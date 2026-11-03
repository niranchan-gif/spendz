const body = "Rs.40.00 is debited from your account XX1234 on 21-09-26 towards VPA kishancafe@hdfc (KISHAN CAFE) on 21-09";

console.log("Testing Regex with missing year:");
const oldStrictRegex = /towards\s+VPA.*\((.*)\)\s+on\s+\d{2}-\d{2}-\d{2}/i;
const myNewRegex = /towards\s+[\s\S]*?\((.*?)\)\s+on\s+\d{2}-\d{2}-\d{2}/i;
const oldFallback = /towards\s+(.*?)\s+on\s+\d{2}-\d{2}/i;

console.log("old strict: ", body.match(oldStrictRegex)); // null
console.log("my new strict: ", body.match(myNewRegex)); // null
console.log("old fallback: ", body.match(oldFallback)?.[1]); // "VPA kishancafe@hdfc (KISHAN CAFE"
