# FPS Chess Mods

FPS Chess Online Mod Loader의 공식 모드 업데이트 채널입니다.

업데이트 기능은 Release의 `fpschess-update-manifest.json`을 확인한 뒤, SHA-256 해시 검증을 통과한 모드 파일만 설치합니다.

## 소스

- `FPSChessAugmentChess/scripts/` — 증강 카드 모드의 현재 개발 소스
- 108장 카드 카탈로그와 일반 기물 전용 카드 필터
- `강철 피부` 피해 감소 훅 및 피해 계산
- 콘솔 카드 지급과 Tab 자동 완성
- `C` 키 보유 카드·증감 수치·최종 스탯 화면

배포 패키지는 Release의 `FPSChessAugmentChess.zip`이며, ZIP 내부에는 `scripts/` 폴더가 들어갑니다.

## UE4SS 디버그 콘솔 끄기

UE4SS 디버그 콘솔 설정은 모드 ZIP에 포함되지 않으며, 모드 자동 업데이트로 변경되지 않습니다. 각 설치의 `FPSChess/Binaries/Win64/UE4SS-settings.ini`에서 필요한 값만 다음과 같이 바꾸세요. 전체 파일을 교체하면 `ModsFolderPath` 같은 설치별 경로가 덮어써질 수 있습니다.

자세한 키와 적용 방법은 [`UE4SS-DEBUG-FIX.md`](UE4SS-DEBUG-FIX.md)를 참고하세요.
