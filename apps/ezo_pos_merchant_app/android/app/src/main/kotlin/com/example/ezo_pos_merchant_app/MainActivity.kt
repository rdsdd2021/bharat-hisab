package com.example.ezo_pos_merchant_app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bharathisab.pos/bluetooth_printer"
    private val SCALE_CHANNEL = "com.bharathisab.pos/weighing_scale"
    private val SCALE_STREAM_CHANNEL = "com.bharathisab.pos/weighing_scale_stream"
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        BluetoothAdapter.getDefaultAdapter()
    }

    private val usbManager: UsbManager? by lazy {
        getSystemService(Context.USB_SERVICE) as? UsbManager
    }

    private var activeSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private val discoveredDevices = mutableListOf<Map<String, String>>()
    private var discoveryReceiver: BroadcastReceiver? = null

    // Weighing Scale state
    private var scaleSocket: BluetoothSocket? = null
    private var scaleInputStream: InputStream? = null
    private var scaleOutputStream: OutputStream? = null
    private var isScaleReading = false
    private var scaleEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothAvailable" -> {
                    result.success(bluetoothAdapter != null)
                }

                "isBluetoothEnabled" -> {
                    result.success(bluetoothAdapter?.isEnabled == true)
                }

                "getBondedDevices" -> {
                    try {
                        val devices = mutableListOf<Map<String, String>>()
                        val paired = bluetoothAdapter?.bondedDevices
                        if (paired != null) {
                            for (device in paired) {
                                val name = try { device.name ?: "Unknown Printer" } catch (e: SecurityException) { "Paired Device" }
                                devices.add(mapOf(
                                    "name" to name,
                                    "address" to device.address,
                                    "isBonded" to "true"
                                ))
                            }
                        }
                        result.success(devices)
                    } catch (e: Exception) {
                        result.error("BONDED_ERROR", e.localizedMessage, null)
                    }
                }

                "startDiscovery" -> {
                    try {
                        discoveredDevices.clear()
                        // Unregister previous if any
                        discoveryReceiver?.let {
                            try { unregisterReceiver(it) } catch (ignored: Exception) {}
                        }

                        discoveryReceiver = object : BroadcastReceiver() {
                            override fun onReceive(context: Context, intent: Intent) {
                                when (intent.action) {
                                    BluetoothDevice.ACTION_FOUND -> {
                                        val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                                        } else {
                                            @Suppress("DEPRECATION")
                                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                                        }
                                        if (device != null) {
                                            val name = try { device.name ?: "Nearby Bluetooth Device" } catch (e: SecurityException) { "Bluetooth Device" }
                                            val address = device.address
                                            if (discoveredDevices.none { it["address"] == address }) {
                                                discoveredDevices.add(mapOf(
                                                    "name" to name,
                                                    "address" to address,
                                                    "isBonded" to (device.bondState == BluetoothDevice.BOND_BONDED).toString()
                                                ))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        val filter = IntentFilter(BluetoothDevice.ACTION_FOUND)
                        registerReceiver(discoveryReceiver, filter)
                        bluetoothAdapter?.startDiscovery()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DISCOVERY_ERROR", e.localizedMessage, null)
                    }
                }

                "getDiscoveredDevices" -> {
                    result.success(ArrayList(discoveredDevices))
                }

                "stopDiscovery" -> {
                    try {
                        bluetoothAdapter?.cancelDiscovery()
                        discoveryReceiver?.let {
                            try { unregisterReceiver(it) } catch (ignored: Exception) {}
                        }
                        discoveryReceiver = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "connect" -> {
                    val address = call.argument<String>("address")
                    if (address == null) {
                        result.error("INVALID_ARG", "Device address is required", null)
                        return@setMethodCallHandler
                    }

                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            bluetoothAdapter?.cancelDiscovery()
                            val device = bluetoothAdapter?.getRemoteDevice(address)
                            if (device == null) {
                                withContext(Dispatchers.Main) {
                                    result.error("DEVICE_NOT_FOUND", "Could not find Bluetooth device $address", null)
                                }
                                return@launch
                            }

                            // Close previous connection if any
                            try {
                                outputStream?.close()
                                activeSocket?.close()
                            } catch (ignored: Exception) {}

                            val socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                            socket.connect()

                            activeSocket = socket
                            outputStream = socket.outputStream

                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            try {
                                activeSocket?.close()
                            } catch (ignored: Exception) {}
                            activeSocket = null
                            outputStream = null
                            withContext(Dispatchers.Main) {
                                result.error("CONNECT_FAILED", "Failed to connect to printer: ${e.localizedMessage}", null)
                            }
                        }
                    }
                }

                "sendBytes" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("INVALID_ARG", "Bytes payload cannot be null", null)
                        return@setMethodCallHandler
                    }

                    val stream = outputStream
                    val socket = activeSocket
                    if (stream == null || socket == null || !socket.isConnected) {
                        result.error("NOT_CONNECTED", "No active Bluetooth printer connection", null)
                        return@setMethodCallHandler
                    }

                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            stream.write(bytes)
                            stream.flush()
                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("WRITE_ERROR", "Failed to write ESC/POS bytes: ${e.localizedMessage}", null)
                            }
                        }
                    }
                }

                "disconnect" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            outputStream?.close()
                            activeSocket?.close()
                        } catch (ignored: Exception) {}
                        activeSocket = null
                        outputStream = null
                        withContext(Dispatchers.Main) {
                            result.success(true)
                        }
                    }
                }

                "isConnected" -> {
                    val connected = activeSocket?.isConnected == true
                    result.success(connected)
                }

                else -> result.notImplemented()
            }
        }

        // Weighing Scale Event Channel (Live Weight Stream)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCALE_STREAM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    scaleEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    scaleEventSink = null
                }
            }
        )

        // Weighing Scale Method Channel (Connect, Tare, Zero, Port Discovery)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCALE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBondedScales" -> {
                    try {
                        val devices = mutableListOf<Map<String, String>>()
                        val paired = bluetoothAdapter?.bondedDevices
                        if (paired != null) {
                            for (device in paired) {
                                val name = try { device.name ?: "Unknown Scale" } catch (e: SecurityException) { "Bluetooth Scale" }
                                devices.add(mapOf(
                                    "name" to name,
                                    "address" to device.address,
                                    "type" to "bluetooth"
                                ))
                            }
                        }
                        result.success(devices)
                    } catch (e: Exception) {
                        result.error("DISCOVERY_ERROR", e.localizedMessage, null)
                    }
                }

                "getUsbDevices" -> {
                    try {
                        val list = mutableListOf<Map<String, Any>>()
                        val devices = usbManager?.deviceList
                        if (devices != null) {
                            for ((_, device) in devices) {
                                val name = device.productName ?: "USB Serial Scale (${device.vendorId}:${device.productId})"
                                list.add(mapOf(
                                    "name" to name,
                                    "address" to "USB_${device.deviceId}",
                                    "vendorId" to device.vendorId,
                                    "productId" to device.productId,
                                    "type" to "usb"
                                ))
                            }
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("USB_ERROR", e.localizedMessage, null)
                    }
                }

                "connectBluetoothScale" -> {
                    val address = call.argument<String>("address")
                    if (address == null) {
                        result.error("INVALID_ARG", "Device address is required", null)
                        return@setMethodCallHandler
                    }

                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            bluetoothAdapter?.cancelDiscovery()
                            val device = bluetoothAdapter?.getRemoteDevice(address)
                            if (device == null) {
                                withContext(Dispatchers.Main) {
                                    result.error("DEVICE_NOT_FOUND", "Could not find Bluetooth scale $address", null)
                                }
                                return@launch
                            }

                            // Close previous connection if any
                            isScaleReading = false
                            try {
                                scaleInputStream?.close()
                                scaleOutputStream?.close()
                                scaleSocket?.close()
                            } catch (ignored: Exception) {}

                            val socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                            socket.connect()

                            scaleSocket = socket
                            scaleInputStream = socket.inputStream
                            scaleOutputStream = socket.outputStream
                            isScaleReading = true

                            // Start background reading coroutine
                            startScaleReadingLoop()

                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            try {
                                scaleSocket?.close()
                            } catch (ignored: Exception) {}
                            scaleSocket = null
                            scaleInputStream = null
                            scaleOutputStream = null
                            isScaleReading = false
                            withContext(Dispatchers.Main) {
                                result.error("CONNECT_FAILED", "Failed to connect to scale: ${e.localizedMessage}", null)
                            }
                        }
                    }
                }

                "tareScale" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            scaleOutputStream?.write("T\r\n".toByteArray())
                            scaleOutputStream?.flush()
                            withContext(Dispatchers.Main) { result.success(true) }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) { result.success(false) }
                        }
                    }
                }

                "zeroScale" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            scaleOutputStream?.write("Z\r\n".toByteArray())
                            scaleOutputStream?.flush()
                            withContext(Dispatchers.Main) { result.success(true) }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) { result.success(false) }
                        }
                    }
                }

                "disconnectScale" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        isScaleReading = false
                        try {
                            scaleInputStream?.close()
                            scaleOutputStream?.close()
                            scaleSocket?.close()
                        } catch (ignored: Exception) {}
                        scaleSocket = null
                        scaleInputStream = null
                        scaleOutputStream = null
                        withContext(Dispatchers.Main) {
                            result.success(true)
                        }
                    }
                }

                "isScaleConnected" -> {
                    val connected = scaleSocket?.isConnected == true
                    result.success(connected)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startScaleReadingLoop() {
        CoroutineScope(Dispatchers.IO).launch {
            val buffer = ByteArray(256)
            val lineBuilder = StringBuilder()

            while (isScaleReading && scaleSocket?.isConnected == true) {
                try {
                    val bytesRead = scaleInputStream?.read(buffer) ?: -1
                    if (bytesRead > 0) {
                        for (i in 0 until bytesRead) {
                            val c = buffer[i].toInt().toChar()
                            if (c == '\n' || c == '\r') {
                                if (lineBuilder.isNotEmpty()) {
                                    val line = lineBuilder.toString().trim()
                                    if (line.isNotEmpty()) {
                                        withContext(Dispatchers.Main) {
                                            scaleEventSink?.success(line)
                                        }
                                    }
                                    lineBuilder.clear()
                                }
                            } else {
                                if (lineBuilder.length < 128) {
                                    lineBuilder.append(c)
                                }
                            }
                        }
                    } else if (bytesRead == -1) {
                        break
                    }
                } catch (e: Exception) {
                    break
                }
            }
        }
    }

    override fun onDestroy() {
        discoveryReceiver?.let {
            try { unregisterReceiver(it) } catch (ignored: Exception) {}
        }
        try {
            outputStream?.close()
            activeSocket?.close()
        } catch (ignored: Exception) {}
        isScaleReading = false
        try {
            scaleInputStream?.close()
            scaleOutputStream?.close()
            scaleSocket?.close()
        } catch (ignored: Exception) {}
        super.onDestroy()
    }
}
