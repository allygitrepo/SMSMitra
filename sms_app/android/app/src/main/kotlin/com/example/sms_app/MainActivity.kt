package com.example.sms_app

import android.content.Context
import android.telephony.SubscriptionManager
import android.telephony.SmsManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.sms_app/sim_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
    }

    private fun sendSms(number: String, message: String, subId: Int?) {
        try {
            val smsManager: SmsManager = if (subId != null && subId != -1) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as android.telephony.TelephonyManager
                    telephonyManager.createForSubscriptionId(subId).run {
                        this@MainActivity.getSystemService(SmsManager::class.java).createForSubscriptionId(subId)
                    }
                } else {
                    @Suppress("DEPRECATION")
                    SmsManager.getSmsManagerForSubscriptionId(subId)
                }
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    this.getSystemService(SmsManager::class.java)
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
            // Handle error
        }
    }

    private fun getSimCards(): List<Map<String, Any?>> {
        val simCards = mutableListOf<Map<String, Any?>>()
        val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
        
        try {
            val activeSubscriptionInfoList = subscriptionManager.activeSubscriptionInfoList
            if (activeSubscriptionInfoList != null) {
                for (info in activeSubscriptionInfoList) {
                    val map = mutableMapOf<String, Any?>()
                    map["id"] = info.subscriptionId.toString()
                    map["carrierName"] = info.displayName.toString()
                    map["slotIndex"] = info.simSlotIndex
                    map["number"] = info.number ?: "Unknown Number"
                    simCards.add(map)
                }
            }
        } catch (e: SecurityException) {
            // Permission not granted handled in Flutter
        } catch (e: Exception) {
            // Other errors
        }
        return simCards
    }
}
