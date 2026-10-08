SHELL := /bin/bash

.PHONY: bootstrap domain-test mock test reliability report clean

bootstrap:
	@command -v xcodegen >/dev/null || (echo "Install XcodeGen: brew install xcodegen" && exit 1)
	xcodegen generate

# Runs cross-platform SwiftPM tests for the pure domain package.
domain-test:
	cd Packages/ContactDomain && swift test

mock:
	./scripts/start-mock-server.sh

test: bootstrap
	./scripts/run-tests.sh

reliability: bootstrap
	./scripts/run-reliability.sh

report:
	./scripts/report.sh

clean:
	rm -rf ContactLab.xcodeproj DerivedData reports/*.xcresult reports/*.json reports/*.html reports/reliability
