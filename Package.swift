// swift-tools-version:5.5
import PackageDescription

#if os(Linux)
let systemLibraryName = "System"
#else
let systemLibraryName = "SystemPackage"
#endif

let package = Package(
    name: "BluetoothLinux",
    products: [
        .library(
            name: "BluetoothLinux",
            targets: ["BluetoothLinux"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            .upToNextMajor(from: "5.0.0")
        ),
        .package(
            url: "https://github.com/kubacizek/swift-system.git",
            .branch("master")
        )
    ],
    targets: [
        .target(
            name: "BluetoothLinux",
            dependencies: [
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothHCI",
                    package: "Bluetooth"
                ),
                "CBluetoothLinux",
                .product(
                    name: systemLibraryName,
                    package: "swift-system"
                )
            ]
        ),
        .target(
            name: "CBluetoothLinux"
        ),
        .target(
            name: "CBluetoothLinuxTest"
        ),
        .testTarget(
            name: "BluetoothLinuxTests",
            dependencies: [
                "BluetoothLinux",
                "CBluetoothLinuxTest"
            ]
        )
    ]
)
