const emails = [
  "Rs.40.00 is debited from your account XX1234 on 21-09-26 towards VPA kishancafe@hdfc (KISHAN CAFE) on 21-09-26",
  "Rs.626.00 is debited from your account XX1234 on 10-09-26 towards something@hdfc (MOON NIGHT) on 10-09-26",
  "Rs.100.00 is debited from your account XX1234 on 10-09-26 towards VPA UPI on 10-09-26", // No parentheses
  "Rs.200.00 is debited from your account XX1234 on 10-09-26 towards someone on 10-09-26",
  `Rs.40.00 is debited from your account XX1234 on 21-09-26
towards VPA kishancafe@hdfc (KISHAN CAFE)
on 21-09-26`, // with newlines
  "Rs.40.00 is debited from your account XX1234 on 21-09-26 towards kishancafe@hdfc (KISHAN CAFE) on 21-09-26" // without VPA
];

console.log("Testing Regex:");
const merchantRegex = /towards\s+[\s\S]*?\((.*?)\)\s+on\s+\d{2}-\d{2}-\d{2}/i;
const fallbackRegex = /towards\s+([\s\S]*?)\s+on\s+\d{2}-\d{2}-\d{2}/i;

for (const body of emails) {
  let merchantName = "Unknown";
  let match = body.match(merchantRegex);
  
  if (match) {
    merchantName = match[1].trim();
    console.log(`Matched (parentheses): ${merchantName}`);
  } else {
    let fallback = body.match(fallbackRegex);
    if (fallback) {
      merchantName = fallback[1].trim();
      console.log(`Matched (fallback): ${merchantName}`);
    } else {
      console.log(`FAILED to match: ${body.substring(0, 50)}...`);
    }
  }
}
