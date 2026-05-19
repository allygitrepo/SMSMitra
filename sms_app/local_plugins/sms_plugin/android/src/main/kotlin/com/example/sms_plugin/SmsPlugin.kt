package com.example.sms_plugin

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SmsPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        private const val TAG = "SMSmitra"
        private const val SMS_SENT = "SMS_SENT"
        private const val SMS_DELIVERED = "SMS_DELIVERED"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        context = binding.applicationContext

        channel = MethodChannel(
            binding.binaryMessenger,
            "com.example.sms_app/sim_info"
        )

        channel.setMethodCallHandler(this)

        registerSmsReceivers()
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

                    val sendResult = sendSms(
                        number,
                        message,
                        subId
                    )

                    result.success(sendResult)

                } else {

                    result.error(
                        "INVALID_ARGS",
                        "Number or message is null",
                        null
                    )
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun sendSms(
        number: String,
        message: String,
        subId: Int?
    ): Boolean {

        return try {

            // Normalize number
            val formattedNumber =
                if (
                    !number.startsWith("+91") &&
                    number.length == 10
                ) {
                    "+91$number"
                } else {
                    number
                }

            Log.d(TAG, "Sending SMS to: $formattedNumber")
            Log.d(TAG, "Message: $message")
            Log.d(TAG, "Subscription ID: $subId")

            // Get SMS Manager
            val smsManager: SmsManager =

                if (subId != null && subId != -1) {

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

                        context
                            .getSystemService(SmsManager::class.java)
                            .createForSubscriptionId(subId)

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

            // Sent Intent
            val sentPI = PendingIntent.getBroadcast(
                context,
                System.currentTimeMillis().toInt(),
                Intent(SMS_SENT),
                PendingIntent.FLAG_IMMUTABLE
            )

            // Delivered Intent
            val deliveredPI = PendingIntent.getBroadcast(
                context,
                System.currentTimeMillis().toInt(),
                Intent(SMS_DELIVERED),
                PendingIntent.FLAG_IMMUTABLE
            )

            val parts = smsManager.divideMessage(message)

            Log.d(TAG, "Message Parts Count: ${parts.size}")

            // Multipart SMS
            if (parts.size > 1) {

                val sentIntents =
                    ArrayList<PendingIntent>()

                val deliveryIntents =
                    ArrayList<PendingIntent>()

                for (i in parts.indices) {
                    sentIntents.add(sentPI)
                    deliveryIntents.add(deliveredPI)
                }

                smsManager.sendMultipartTextMessage(
                    formattedNumber,
                    null,
                    parts,
                    sentIntents,
                    deliveryIntents
                )

                Log.d(TAG, "Multipart SMS Sent")

            } else {

                smsManager.sendTextMessage(
                    formattedNumber,
                    null,
                    message,
                    sentPI,
                    deliveredPI
                )

                Log.d(TAG, "Single SMS Sent")
            }

            true

        } catch (e: Exception) {

            Log.e(
                TAG,
                "SMS Sending Failed: ${e.message}",
                e
            )

            false
        }
    }

    private fun getSimCards(): List<Map<String, Any?>> {

        val simCards =
            mutableListOf<Map<String, Any?>>()

        val subscriptionManager =
            context.getSystemService(
                Context.TELEPHONY_SUBSCRIPTION_SERVICE
            ) as SubscriptionManager

        try {

            val activeSubscriptionInfoList =
                subscriptionManager.activeSubscriptionInfoList

            if (activeSubscriptionInfoList != null) {

                for (info in activeSubscriptionInfoList) {

                    val map =
                        mutableMapOf<String, Any?>()

                    map["id"] =
                        info.subscriptionId.toString()

                    val carrier =
                        info.carrierName?.toString()

                    val display =
                        info.displayName?.toString()

                    map["carrierName"] =

                        if (
                            !carrier.isNullOrBlank() &&
                            !carrier.contains(
                                "SIM",
                                ignoreCase = true
                            )
                        ) {

                            carrier

                        } else if (!display.isNullOrBlank()) {

                            display

                        } else {

                            "SIM ${info.simSlotIndex + 1}"
                        }

                    map["slotIndex"] =
                        info.simSlotIndex

                    map["number"] =
                        info.number ?: ""

                    simCards.add(map)
                }
            }

        } catch (e: Exception) {

            Log.e(
                TAG,
                "SIM Fetch Error: ${e.message}",
                e
            )
        }

        return simCards
    }

    private fun registerSmsReceivers() {

        // SMS SENT RECEIVER
        val sentReceiver = object : BroadcastReceiver() {

            override fun onReceive(
                context: Context?,
                intent: Intent?
            ) {

                when (resultCode) {

                    Activity.RESULT_OK -> {

                        Log.d(
                            TAG,
                            "SMS SENT SUCCESSFULLY"
                        )
                    }

                    SmsManager.RESULT_ERROR_GENERIC_FAILURE -> {

                        Log.e(
                            TAG,
                            "SMS FAILED: Generic Failure"
                        )
                    }

                    SmsManager.RESULT_ERROR_NO_SERVICE -> {

                        Log.e(
                            TAG,
                            "SMS FAILED: No Service"
                        )
                    }

                    SmsManager.RESULT_ERROR_NULL_PDU -> {

                        Log.e(
                            TAG,
                            "SMS FAILED: Null PDU"
                        )
                    }

                    SmsManager.RESULT_ERROR_RADIO_OFF -> {

                        Log.e(
                            TAG,
                            "SMS FAILED: Radio Off"
                        )
                    }

                    else -> {

                        Log.e(
                            TAG,
                            "SMS FAILED: Unknown Error"
                        )
                    }
                }
            }
        }

        // SMS DELIVERED RECEIVER
        val deliveredReceiver = object : BroadcastReceiver() {

            override fun onReceive(
                context: Context?,
                intent: Intent?
            ) {

                when (resultCode) {

                    Activity.RESULT_OK -> {

                        Log.d(
                            TAG,
                            "SMS DELIVERED SUCCESSFULLY"
                        )
                    }

                    Activity.RESULT_CANCELED -> {

                        Log.e(
                            TAG,
                            "SMS NOT DELIVERED"
                        )
                    }
                }
            }
        }

        // Register Receivers
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

            context.registerReceiver(
                sentReceiver,
                IntentFilter(SMS_SENT),
                Context.RECEIVER_NOT_EXPORTED
            )

            context.registerReceiver(
                deliveredReceiver,
                IntentFilter(SMS_DELIVERED),
                Context.RECEIVER_NOT_EXPORTED
            )

        } else {

            context.registerReceiver(
                sentReceiver,
                IntentFilter(SMS_SENT)
            )

            context.registerReceiver(
                deliveredReceiver,
                IntentFilter(SMS_DELIVERED)
            )
        }
    }
}