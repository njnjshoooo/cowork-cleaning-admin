const express = require('express');
const router = express.Router();
const { ECPAY_CONFIG, generateCheckMacValue, formatDate, generateTradeNo } = require('../utils/ecpay');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL || 'https://wtckwijqczeivtnlalva.supabase.co',
  process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY || 'sb_publishable_5KK0TEqRi2_KfPCQd-SfJg_lY4lI5_U'
);

// POST /api/create-payment
router.post('/', async (req, res) => {
  try {
    const { orderId, orderNo, amount, paymentType, itemName, customerName, customerEmail, customerPhone } = req.body;

    if (!orderId || !amount) {
      return res.status(400).json({ error: '缺少必要參數：orderId, amount' });
    }

    const merchantTradeNo = generateTradeNo();

    // ECPay 訂單參數
    const params = {
      MerchantID: ECPAY_CONFIG.MerchantID,
      MerchantTradeNo: merchantTradeNo,
      MerchantTradeDate: formatDate(),
      PaymentType: 'aio',
      TotalAmount: Math.round(amount),
      TradeDesc: encodeURIComponent('戶沐淨清潔服務'),
      ItemName: itemName || '清潔服務費用',
      ReturnURL: ECPAY_CONFIG.ReturnURL,
      ClientBackURL: ECPAY_CONFIG.ClientBackURL,
      ChoosePayment: 'ALL',
      EncryptType: 1,
      CustomField1: orderId,
      CustomField2: orderNo || '',
      CustomField3: paymentType || 'full',
    };

    // 產生 CheckMacValue
    params.CheckMacValue = generateCheckMacValue(params);

    // 儲存付款記錄到 Supabase
    await supabase.from('payments').insert({
      id: merchantTradeNo,
      order_id: orderId,
      merchant_trade_no: merchantTradeNo,
      amount: Math.round(amount),
      payment_status: 'pending',
    });

    // 回傳付款資訊
    res.json({
      success: true,
      paymentUrl: ECPAY_CONFIG.PaymentURL,
      params: params,
      merchantTradeNo: merchantTradeNo,
    });

  } catch (error) {
    console.error('Create payment error:', error);
    res.status(500).json({ error: '建立付款失敗：' + error.message });
  }
});

// GET /api/payment-status/:orderId
router.get('/status/:orderId', async (req, res) => {
  try {
    const { data } = await supabase
      .from('payments')
      .select('*')
      .eq('order_id', req.params.orderId)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    res.json({ success: true, payment: data });
  } catch (error) {
    res.json({ success: false, payment: null });
  }
});

module.exports = router;
