from pathlib import Path
import tempfile,shutil,subprocess,os
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='showbook-adapter-') as temp:
 p=Path(temp);(p/'Sources/Adapter').mkdir(parents=True)
 for f in ['Models.swift','NetworkClass.swift']:shutil.copy2(root/'ShowBook/Model'/f,p/'Sources/Adapter'/f)
 shutil.copytree(root/'TestSupport/NetworkingTests',p/'Tests/AdapterTests')
 (p/'Package.swift').write_text('''// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Adapter", platforms: [.macOS(.v14)], dependencies: [.package(url: "https://github.com/Anurag-Chourasia/CommonNetworking.git", exact: "1.0.0")], targets: [.target(name: "Adapter", dependencies: [.product(name: "CommonNetworking", package: "CommonNetworking")]), .testTarget(name: "AdapterTests", dependencies: ["Adapter"], resources: [.process("Fixtures")])], swiftLanguageVersions: [.v5])
''')
 subprocess.run(['xcrun','swift','test','--package-path',str(p),'--triple','arm64-apple-macosx14.0'],check=True)
