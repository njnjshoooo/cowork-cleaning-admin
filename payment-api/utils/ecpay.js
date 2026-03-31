const CryptoJS = require('crypto-js');

// ECPay 測試環境（正式上線時換成正式金鑰）
const ECPAY_CONFIG = {
  MerchantID: process.env.ECPAY_MERCHANT_ID || '3002607',
  HashKey: process.env.ECPAY_HASH_KEY || 'pwFHCqoQZGmho4w6',
  HashIV: process.env.ECPAY_HASH_IV || 'EkRm7iFT261dpevs',
  PaymentURL: process.env.ECPAY_PAYMENT_URL || 'https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5',
  ReturnURL: process.env.PAYMENT_CALLBACK_URL || 'https://api.homood-clean.tw/api/payment-callback',
  ClientBackURL: process.env.CLIENT_URL || 'https://homood-clean.tw',
};

// URL encode（符合 ECPay 規範）
function ecpayUrlEncode(str) {
  let encoded = encodeURIComponent(str);
  // ECPay 特殊字元對應
  encoded = encoded.replace(/%2d/gi, '-');
  encoded = encoded.replace(/%5f/gi, '_');
  encoded = encoded.replace(/%2e/gi, '.');
  encoded = encoded.replace(/%21/gi, '!');
  encoded = encoded.replace(/%2a/gi, '*');
  encoded = encoded.replace(/%28/gi, '(');
  encoded = encoded.replace(/%29/gi, ')');
  encoded = encoded.replace(/%20/gi, '+');
  return encoded.toLowerCase();
}

// 產生 CheckMacValue
function generateCheckMacValue(params) {
  // 1. 按照字母排序
  const sortedKeys = Object.keys(params).sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

  // 2. 組合字串
  let raw = `HashKey=${ECPAY_CONFIG.HashKey}`;
  sortedKeys.forEach(key => {
    raw += `&${key}=${params[key]}`;
  });
  raw += `&HashIV=${ECPAY_CONFIG.HashIV}`;

  // 3. URL encode
  raw = ecpayUrlEncode(raw);

  // 4. SHA256 + 轉大寫
  const hash = CryptoJS.SHA256(raw).toString(CryptoJS.enc.Hex).toUpperCase();

  return hash;
}

// 驗證 ECPay 回傳的 CheckMacValue
function verifyCheckMacValue(params) {
  const receivedMac = params.CheckMacValue;
  const paramsWithoutMac = { ...params };
  delete paramsWithoutMac.CheckMacValue;

  const calculatedMac = generateCheckMacValue(paramsWithoutMac);
  return receivedMac === calculatedMac;
}

// 格式化日期為 ECPay 格式
function formatDate(date) {
  const d = date || new Date();
  const yyyy = d.getFullYear();
  const MM = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  const HH = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  const ss = String(d.getSeconds()).padStart(2, '0');
  return `${yyyy}/${MM}/${dd} ${HH}:${mm}:${ss}`;
}

// 產生唯一交易編號（最長20碼）
function generateTradeNo() {
  return 'HM' + Date.now().toString().slice(-12) + Math.random().toString(36).slice(2, 6).toUpperCase();
}

module.exports = {
  ECPAY_CONFIG,
  generateCheckMacValue,
  verifyCheckMacValue,
  formatDate,
  generateTradeNo,
};
