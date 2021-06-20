// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "BMSCamera",
	platforms: [.iOS(.v11)],
	products: [
		.library(
			name: "BMSCamera",
			targets: ["BMSCamera"]),
	],
	dependencies: [
		.package(name: "SnapKit", url: "https://github.com/SnapKit/SnapKit.git", .upToNextMajor(from: "5.0.1"))
	],
	targets: [

		.target(
			name: "BMSCamera",
			dependencies: [
				.product(name: "SnapKit", package: "SnapKit")]),

	]
)
