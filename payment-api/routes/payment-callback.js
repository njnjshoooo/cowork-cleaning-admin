const express = require('express');
const router = express.Router();
const { verifyCheckMacValue } = require('../utils/ecpay');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL || 'https://wtckwijqczeivtnlalva.supabase.co',
  process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY || 'sb_publishable_5KK0TEqRi2_KfPCQd-SfJg_lY4lI5_U'
);

// POST /api/payment-callback (ECPay ReturnURL)
router.post('/', async (req, res) => {
  try {
    const params = req.body;
    console.log('ECPay callback received:', JSON.stringify(params));

    // 1. 驗證 CheckMacValue
    if (!verifyCheckMacValue(params)) {
      console.error('CheckMacValue verification failed');
      return res.send('0|CheckMacValue Error');
    }

    const merchantTradeNo = params.MerchantTradeNo;
    const rtnCode = params.RtnCode;
    const tradeNo = params.TradeNo;
    const paymentDate = params.PaymentDate;
    const paymentType = params.PaymentType;
    const orderId = params.CustomField1;

    // 2. 付款成功 (RtnCode === '1')
    if (rtnCode === '1') {
      // 更新 payments 記錄
      await supabase.from('payments').update({
        payment_status: 'paid',
        ecpay_trade_no: tradeNo,
        payment_method: paymentType,
        paid_at: new Date().toISOString(),
      }).eq('merchant_trade_no', merchantTradeNo);

      // 更新訂單狀態為「已付定金」或自訂狀態
      if (orderId) {
        await supabase.from('orders').update({
          status: 'deposit_paid',
          payment_method: getPaymentMethodLabel(paymentType),
        }).eq('id', orderId);
      }

      console.log(`Payment success: ${merchantTradeNo}, Order: ${orderId}`);
    } else {
      // 付款失敗
      await supabase.from('payments').update({
        payment_status: 'failed',
      }).eq('merchant_trade_no', merchantTradeNo);

      console.log(`Payment failed: ${merchantTradeNo}, RtnCode: ${rtnCode}`);
    }

    // 3. 回傳 '1|OK' 給 ECPay（必須）
    res.send('1|OK');

  } catch (error) {
    console.error('Payment callback error:', error);
    res.send('0|Error');
  }
});

// 將 ECPay 付款類型轉為中文
function getPaymentMethodLabel(paymentType) {
  const map = {
    'Credit_CreditCard': '信用卡',
    'TWQR_OPAY': 'TWQR',
    'ATM_TAISHIN': 'ATM',
    'ATM_ESUN': 'ATM',
    'ATM_BOT': 'ATM',
    'ATM_FUBON': 'ATM',
    'ATM_CHINATRUST': 'ATM',
    'ATM_FIRST': 'ATM',
    'ATM_LAND': 'ATM',
    'ATM_CATHAY': 'ATM',
    'ATM_MEGA': 'ATM',
    'CVS_CVS': '超商代碼',
    'CVS_OK': '超商代碼',
    'CVS_FAMILY': '超商代碼',
    'CVS_HILIFE': '超商代碼',
    'CVS_IBON': '超商代碼',
    'BARCODE_BARCODE': '超商條碼',
  };
  return map[paymentType] || paymentType || '線上付款';
}

module.exports = router;
