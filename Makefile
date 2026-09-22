# 자주 쓰는 Flutter 명령 모음.
#
# 키를 빌드에 심는 `--dart-define-from-file` 을 매번 타이핑하지 않으려고 둔다.
# .env.json 이 없으면 플래그 없이 실행하므로, 키 없이 클론한 사람도 그대로 쓸 수 있다.
#
#   make run                 연결된 기기 중 하나로 실행
#   make run DEVICE=macos    기기 지정
#   make ios / make macos    플랫폼 바로 지정
#   make devices             기기 목록과 ID 확인
#   make test / make analyze
#   make ipa / make apk      릴리스 빌드

ENV_FILE ?= .env.json
DEFINES  := $(if $(wildcard $(ENV_FILE)),--dart-define-from-file=$(ENV_FILE),)

DEVICE     ?=
DEVICE_ARG := $(if $(DEVICE),-d $(DEVICE),)

.PHONY: run ios macos devices test analyze ipa apk env-check

run:
	flutter run $(DEFINES) $(DEVICE_ARG)

ios:
	$(MAKE) run DEVICE=ios

macos:
	$(MAKE) run DEVICE=macos

devices:
	flutter devices

test:
	flutter test $(DEFINES)

analyze:
	flutter analyze

ipa:
	flutter build ipa $(DEFINES)

apk:
	flutter build apk $(DEFINES)

# 키가 심긴 채로 빌드되는지 확인만 한다. 값 자체는 출력하지 않는다.
env-check:
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(ENV_FILE) 있음 → 빌드에 키를 심습니다"; \
	else \
		echo "$(ENV_FILE) 없음 → 설정 화면에서 받은 키만 씁니다"; \
	fi
