import PackageDescription

let package = Package(
    name: "PhoenixCouchDB",

    dependencies: [.Package(url: "git@github.ibm.com:ibmswift/Phoenix.git", majorVersion: 0),
    	.Package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", majorVersion: 2)
    ]
)