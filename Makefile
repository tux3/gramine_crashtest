.PHONY: all clean build-debug rust-debug build-release rust-release sign-release sign-debug get-token-release get-token-debug

PROJNAME=gramine_epoll_repro
SGX_SIGNER_KEY=test_key.pem

all: target/debug/${PROJNAME}.manifest


rust-debug:
	cargo build

rust-release:
	cargo build --release

target/debug/${PROJNAME}.manifest: EXE_DIR?=target/debug/
target/debug/${PROJNAME}.manifest: ${PROJNAME}.manifest.template rust-debug
	gramine-manifest -Dlibdir=/lib/x86_64-linux-gnu/ \
					 -Dself_exe=${EXE_DIR}${PROJNAME} \
					 -Dlog_level=debug \
					 $< $@

build-debug: target/debug/${PROJNAME}.manifest


target/debug/${PROJNAME}.manifest.sgx: target/debug/${PROJNAME}.manifest
	gramine-sgx-sign --key ${SGX_SIGNER_KEY} \
					--manifest $(@D)/$(<F) \
					--output $(@D)/$(<F).sgx \

target/debug/${PROJNAME}.sig: target/debug/${PROJNAME}.manifest.sgx


sign-debug: target/debug/${PROJNAME}.sig

target/release/${PROJNAME}.manifest: ${PROJNAME}.manifest.template rust-release
	$(eval EXE_DIR ?= target/release/)
	gramine-manifest -Dlibdir=/lib/x86_64-linux-gnu/ \
					 -Dself_exe=${EXE_DIR}${PROJNAME} \
					 -Dlog_level=error \
					 $< $@

build-release: target/release/${PROJNAME}.manifest


target/release/${PROJNAME}.manifest.sgx: target/release/${PROJNAME}.manifest
	gramine-sgx-sign --key ${SGX_SIGNER_KEY} \
					--manifest $(@D)/$(<F) \
					--output $(@D)/$(<F).sgx \

target/release/${PROJNAME}.sig: target/release/${PROJNAME}.manifest.sgx


sign-release: target/release/${PROJNAME}.sig


target/debug/${PROJNAME}.token: target/debug/${PROJNAME}.sig
	gramine-sgx-get-token --sig target/debug/${PROJNAME}.sig --output target/debug/${PROJNAME}.token

get-token-debug: target/debug/${PROJNAME}.token


target/release/${PROJNAME}.token: target/release/${PROJNAME}.sig
	gramine-sgx-get-token --sig target/release/${PROJNAME}.sig --output target/release/${PROJNAME}.token

get-token-release: target/release/${PROJNAME}.token

run-debug: get-token-debug
	gramine-sgx ./target/debug/${PROJNAME}

run-release: get-token-release
	gramine-sgx ./target/release/${PROJNAME}

clean:
	cargo clean

