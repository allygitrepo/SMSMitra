package com.example.sms_app

import android.content.Context
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SmsPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.example.sms_app/sim_info")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getSimCards" -> {
                val simList = getSimCards()
                result.success(simList)
            }
            "sendSms" -> {
                val number = call.argument<String>("number")
                val message = call.argument<String>("message")
                val subId = call.argument<Int>("subscriptionId")
                
                if (number != null && message != null) {
                    sendSms(number, message, subId)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Number or message is null", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun sendSms(number: String, message: String, subId: Int?) {
        try {
            val smsManager: SmsManager = if (subId != null && subId != -1) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    context.getSystemService(SmsManager::class.java).createForSubscriptionId(subId)
                } else {
                    @Suppress("DEPRECATION")
                    SmsManager.getSmsManagerForSubscriptionId(subId)
                }
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    context.getSystemService(SmsManager::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    SmsManager.getDefault()
                }
            }

            val parts = smsManager.divideMessage(message)
            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(number, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(number, null, message, null, null)
            }
        } catch (e: Exception) {
            // Error handling
        }
    }

    private fun getSimCards(): List<Map<String, Any?>> {
        val simCards = mutableListOf<Map<String, Any?>>()
        val subscriptionManager = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
        
        try {
            val activeSubscriptionInfoList = subscriptionManager.activeSubscriptionInfoList
            if (activeSubscriptionInfoList != null) {
                for (info in activeSubscriptionInfoList) {
                    val map = mutableMapOf<String, Any?>()
                    map["id"] = info.subscriptionId.toString()
                    val carrier = info.carrierName?.toString()
                    val display = info.displayName?.toString()
                    
                    map["carrierName"] = if (!carrier.isNullOrBlank() && !carrier.contains("SIM", ignoreCase = true)) {
                        carrier
                    } else if (!display.isNullOrBlank()) {
                        display
                    } else {
                        "SIM ${info.simSlotIndex + 1}"
                    }

                    map["slotIndex"] = info.simSlotIndex
                    map["number"] = info.number ?: ""
                    simCards.add(map)
                }
            }
        } catch (e: Exception) {
            // Error handling
        }
        return simCards
    }
}
