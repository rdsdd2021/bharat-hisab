package com.example.ezo_pos_merchant_app

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
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
    private val PERMISSION_CHANNEL = "com.bharathisab.pos/permissions"
    private val PERMISSION_REQ_CODE = 2001
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private var pendingPermissionResult: MethodChannel.Result? = null

    private val bluetoothAdapter: BluetoothAdapter?
        get() {
            val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            return manager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
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

    /**
     * Connects to a Bluetooth device with a 4-tier fallback strategy:
     * 1. Standard SDP RFCOMM (SPP UUID)
     * 2. Reflection channel 1 (standard for 99% of ESC/POS thermal printers)
     * 3. Insecure RFCOMM SDP
     * 4. Reflection insecure channel 1
     */
    private fun connectRfcommWithFallback(device: BluetoothDevice): BluetoothSocket {
        // Tier 1: Standard SDP RFCOMM
        try {
            val socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            socket.connect()
            Log.i("POS_BT", "Successfully connected via standard SPP UUID: ${device.address}")
            return socket
        } catch (e1: Exception) {
            Log.w("POS_BT", "Standard SPP connect failed (${e1.message}), trying reflection channel 1 fallback...")
        }

        // Tier 2: Reflection channel 1
        try {
            val method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
            val socket = method.invoke(device, 1) as BluetoothSocket
            socket.connect()
            Log.i("POS_BT", "Successfully connected via reflection channel 1: ${device.address}")
            return socket
        } catch (e2: Exception) {
            Log.w("POS_BT", "Reflection channel 1 failed (${e2.message}), trying insecure SDP...")
        }

        // Tier 3: Insecure SDP
        try {
            val socket = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID)
            socket.connect()
            Log.i("POS_BT", "Successfully connected via insecure SPP: ${device.address}")
            return socket
        } catch (e3: Exception) {
            Log.w("POS_BT", "Insecure SPP connect failed (${e3.message}), trying insecure reflection channel 1...")
        }

        // Tier 4: Insecure reflection channel 1
        val methodInsecure = device.javaClass.getMethod("createInsecureRfcommSocket", Int::class.javaPrimitiveType)
        val socket = methodInsecure.invoke(device, 1) as BluetoothSocket
        socket.connect()
        Log.i("POS_BT", "Successfully connected via insecure reflection channel 1: ${device.address}")
        return socket
    }

    private fun getRequiredPermissions(): Array<String> {
        val list = mutableListOf<String>()
        list.add(Manifest.permission.CAMERA)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            list.add(Manifest.permission.BLUETOOTH_SCAN)
            list.add(Manifest.permission.BLUETOOTH_CONNECT)
        }
        list.add(Manifest.permission.ACCESS_FINE_LOCATION)
        list.add(Manifest.permission.ACCESS_COARSE_LOCATION)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            list.add(Manifest.permission.BLUETOOTH)
            list.add(Manifest.permission.BLUETOOTH_ADMIN)
        }
        return list.toTypedArray()
    }

    private fun getBluetoothPermissions(): Array<String> {
        val list = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            list.add(Manifest.permission.BLUETOOTH_SCAN)
            list.add(Manifest.permission.BLUETOOTH_CONNECT)
        }
        list.add(Manifest.permission.ACCESS_FINE_LOCATION)
        list.add(Manifest.permission.ACCESS_COARSE_LOCATION)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            list.add(Manifest.permission.BLUETOOTH)
            list.add(Manifest.permission.BLUETOOTH_ADMIN)
        }
        return list.toTypedArray()
    }

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
                            kotlinx.coroutines.delay(150)

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

                            val socket = connectRfcommWithFallback(device)

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

                "openBluetoothSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.localizedMessage, null)
                    }
                }

                "requestEnableBluetooth" -> {
                    try {
                        if (bluetoothAdapter?.isEnabled == false) {
                            val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ENABLE_ERROR", e.localizedMessage, null)
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
                            // Chunked byte transmission (512B) prevents small thermal buffer overflows
                            val chunkSize = 512
                            var offset = 0
                            while (offset < bytes.size) {
                                val len = minOf(chunkSize, bytes.size - offset)
                                stream.write(bytes, offset, len)
                                stream.flush()
                                offset += len
                                if (offset < bytes.size) {
                                    kotlinx.coroutines.delay(8)
                                }
                            }
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
                            kotlinx.coroutines.delay(150)

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

                            val socket = connectRfcommWithFallback(device)

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

        // Hardware Permissions Channel (Bluetooth, Location, Camera)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val status = mutableMapOf<String, Any>()
                    var allGranted = true
                    for (perm in getRequiredPermissions()) {
                        val granted = ContextCompat.checkSelfPermission(this, perm) == PackageManager.PERMISSION_GRANTED
                        status[perm] = granted
                        if (!granted) allGranted = false
                    }
                    val btGranted = getBluetoothPermissions().all {
                        ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
                    }
                    val camGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
                    status["allGranted"] = allGranted
                    status["bluetooth"] = btGranted
                    status["camera"] = camGranted
                    result.success(status)
                }

                "requestPermissions" -> {
                    val missing = getRequiredPermissions().filter {
                        ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
                    }.toTypedArray()

                    if (missing.isEmpty()) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(this, missing, PERMISSION_REQ_CODE)
                    }
                }

                "requestBluetoothPermission" -> {
                    val missing = getBluetoothPermissions().filter {
                        ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
                    }.toTypedArray()

                    if (missing.isEmpty()) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(this, missing, PERMISSION_REQ_CODE)
                    }
                }

                "requestCameraPermission" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), PERMISSION_REQ_CODE)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQ_CODE) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermissionResult?.success(allGranted)
            pendingPermissionResult = null
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
