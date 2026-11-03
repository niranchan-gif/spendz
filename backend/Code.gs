/**
 * Phase 4 - Spendz HDFC Gmail Stateless Date-Range API
 * 
 * Instructions:
 * 1. Replace Code.gs with this file
 * 2. Deploy as a Web App (Execute as: Me, Who has access: Anyone)
 * 3. Copy the Web App URL to your Flutter app config
 */

const CONFIG = {
  TIMEZONE: 'Asia/Kolkata',
  GMAIL_SENDER: 'alerts@hdfcbank.bank.in'
};

// ==================================================
// PARSER UTILITIES
// ==================================================

function normalizeMerchant(name) {
  if (!name) return "";
  return name.trim().replace(/\s+/g, ' ');
}

function extractReference(body) {
  // Support both "UPI transaction reference no." and "UPI Reference No."
  const refRegex = /UPI\s+(?:transaction\s+)?reference\s+no\.?\s*:\s*(\d+)/i;
  const match = body.match(refRegex);
  return match ? match[1] : null;
}

function extractTransactionDate(dateStr) {
  // Supports "21-09-26" -> "2026-09-21"
  const parts = dateStr.split('-');
  if (parts.length === 3) {
    let year = parts[2];
    if (year.length === 2) year = '20' + year;
    return `${year}-${parts[1]}-${parts[0]}`;
  }
  return null;
}

function parseHdfcEmail(body) {
  if (body.toUpperCase().includes("VIJAYALAKSHMI MUTHUKUMAR") || body.toUpperCase().includes("MUTHUKUMAR")) {
    return null;
  }
  
  const reference = extractReference(body);
  if (!reference) return null;
  
  let tx = null;
  
  // Try Debit
  const debitAmountRegex = /Rs\.?\s*([\d,]+\.\d{1,2})\s+is\s+debited\s+from\s+your\s+account/i;
  const debitMatch = body.match(debitAmountRegex);
  
  if (debitMatch) {
    const rawAmount = debitMatch[1].replace(/,/g, '');
    const dateRegex = /on\s+(\d{2}-\d{2}-\d{2})/;
    const dateMatch = body.match(dateRegex);
    
    const merchantRegex = /towards\s+[\s\S]*?\((.*?)\)\s+on\s+\d{2}-\d{2}(?:-\d{2})?/i;
    let merchantMatch = body.match(merchantRegex);
    let merchantName = "Unknown";
    
    if (merchantMatch) {
      merchantName = normalizeMerchant(merchantMatch[1]);
    } else {
      // Fallback: extract anything between 'towards' and 'on'
      const fallbackRegex = /towards\s+([\s\S]*?)\s+on\s+\d{2}-\d{2}(?:-\d{2})?/i;
      const fallbackMatch = body.match(fallbackRegex);
      if (fallbackMatch) {
        merchantName = normalizeMerchant(fallbackMatch[1]);
      }
    }
    
    tx = {
      reference: reference,
      name: merchantName,
      amount: parseFloat(rawAmount),
      date: dateMatch ? extractTransactionDate(dateMatch[1]) : null,
      type: "DEBIT",
      source: "HDFC"
    };
  } else {
    // Try Credit
    const creditAmountRegex = /Rs\.?\s*([\d,]+\.\d{1,2})\s+has\s+been\s+successfully\s+credited/i;
    const creditMatch = body.match(creditAmountRegex);
    
    if (creditMatch) {
      const rawAmount = creditMatch[1].replace(/,/g, '');
      const dateRegex = /Date:\s+(\d{2}-\d{2}-\d{2})/;
      const dateMatch = body.match(dateRegex);
      
      const merchantRegex = /Sender:\s+(.*?)\s+(?:Date:|VPA:)/i;
      let merchantMatch = body.match(merchantRegex);
      let merchantName = "Unknown";
      
      if (merchantMatch) {
        merchantName = normalizeMerchant(merchantMatch[1]);
      }
      
      tx = {
        reference: reference,
        name: merchantName,
        amount: parseFloat(rawAmount),
        date: dateMatch ? extractTransactionDate(dateMatch[1]) : null,
        type: "CREDIT",
        source: "HDFC"
      };
    }
  }
  
  if (!tx || !tx.amount || !tx.date || !tx.type) return null;
  
  return tx;
}

// ==================================================
// CORE LOGIC
// ==================================================

function searchHdfcEmails(fromDateStr, toDateStr) {
  // Gmail format: after:YYYY/MM/DD before:YYYY/MM/DD
  // `before:` is exclusive. To include `toDateStr`, we add 1 day to it.
  const fromParts = fromDateStr.split('-');
  const toParts = toDateStr.split('-');
  
  const fromObj = new Date(fromParts[0], fromParts[1] - 1, fromParts[2]);
  const toObj = new Date(toParts[0], toParts[1] - 1, Number(toParts[2]) + 1);
  
  const afterStr = Utilities.formatDate(fromObj, CONFIG.TIMEZONE, 'yyyy/MM/dd');
  const beforeStr = Utilities.formatDate(toObj, CONFIG.TIMEZONE, 'yyyy/MM/dd');
  
  const query = `from:${CONFIG.GMAIL_SENDER} after:${afterStr} before:${beforeStr}`;
  Logger.log("Gmail Query: " + query);
  
  const threads = GmailApp.search(query);
  const transactions = [];
  const seenRefs = {}; // Intra-batch deduplication
  
  for (const thread of threads) {
    const messages = thread.getMessages();
    for (const msg of messages) {
      const body = msg.getPlainBody();
      const tx = parseHdfcEmail(body);
      
      if (tx) {
        // Only include if date is within bounds and reference is new to this batch
        if (tx.date >= fromDateStr && tx.date <= toDateStr) {
          if (!seenRefs[tx.reference]) {
            seenRefs[tx.reference] = true;
            transactions.push(tx);
          }
        }
      }
    }
  }
  
  return transactions;
}

// ==================================================
// FLUTTER API (WEB APP)
// ==================================================

function doGet(e) {
  try {
    const today = new Date();
    const tenDaysAgo = new Date();
    tenDaysAgo.setDate(today.getDate() - 10);
    
    const fromStr = Utilities.formatDate(tenDaysAgo, CONFIG.TIMEZONE, 'yyyy-MM-dd');
    const toStr = Utilities.formatDate(today, CONFIG.TIMEZONE, 'yyyy-MM-dd');
    
    Logger.log(`API called for last 10 days: ${fromStr} to ${toStr}`);
    
    const transactions = searchHdfcEmails(fromStr, toStr);
    
    const response = {
      success: true,
      from: fromStr,
      to: toStr,
      count: transactions.length,
      transactions: transactions
    };
    
    return ContentService
      .createTextOutput(JSON.stringify(response))
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (err) {
    Logger.log("API Error: " + err.message);
    return ContentService
      .createTextOutput(JSON.stringify({
        success: false,
        error: "Unable to collect HDFC transactions for the requested date range."
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// ==================================================
// TESTS
// ==================================================

function testParseKnownHdfcEmails() {
  const tests = [
    {
      body: "Rs.40.00 is debited from your account towards VPA kishancafe@hdfc (KISHAN CAFE) on 21-09-26. UPI transaction reference no.: 626459921108.",
      expected: { name: "KISHAN CAFE", amount: 40, date: "2026-09-21", type: "DEBIT", ref: "626459921108" }
    },
    {
      body: "Rs.626.00 is debited from your account towards VPA something@hdfc (MOON NIGHT) on 10-09-26. UPI transaction reference no.: 625354816548.",
      expected: { name: "MOON NIGHT", amount: 626, date: "2026-09-10", type: "DEBIT", ref: "625354816548" }
    },
    {
      body: "Rs.10000.00 has been successfully credited to your account.\nSender: VIJAYALAKSHMI MUTHUKUMAR\nDate: 14-09-26\nUPI Reference No.: 662320764261",
      expected: { name: "VIJAYALAKSHMI MUTHUKUMAR", amount: 10000, date: "2026-09-14", type: "CREDIT", ref: "662320764261" }
    }
  ];
  
  for (const t of tests) {
    const tx = parseHdfcEmail(t.body);
    if (!tx) {
      Logger.log("FAILED to parse: " + t.body);
      continue;
    }
    
    if (tx.name === t.expected.name && 
        tx.amount === t.expected.amount && 
        tx.date === t.expected.date && 
        tx.type === t.expected.type && 
        tx.reference === t.expected.ref) {
      Logger.log("PASS: " + t.expected.name);
    } else {
      Logger.log("FAIL: " + JSON.stringify(tx) + " expected: " + JSON.stringify(t.expected));
    }
  }
}
