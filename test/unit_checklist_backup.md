# Backup: 백업 스케줄러 Unit 테스트 시나리오

## 실행 방법

```bash
python test/test_unit_backup.py
```

---

## 1. 백업 파일명 형식

- [ ] **test_backup_filename_format**: `get_backup_filename()` 호출 시 오늘 날짜 형식의 `snowball_YYYYMMDD.db` 파일명이 반환되는지 확인

---

## 2. 백업 정리 - 디렉토리 없음

- [ ] **test_backup_cleanup_no_dir**: 백업 디렉토리가 없을 때 `cleanup_old_backups()` 호출 시 `{success: True, deleted_count: 0}`을 반환하는지 확인

---

## 3. 백업 정리 - 오래된 파일 삭제

- [ ] **test_backup_cleanup_deletes_old_files**: 보관 기간(7일)을 초과한 파일(9일 전)이 있을 때 `cleanup_old_backups()` 호출 시 해당 파일이 삭제되고 `deleted_count=1`이 반환되는지 확인

---

## 4. 백업 정리 - 최근 파일 유지

- [ ] **test_backup_cleanup_keeps_recent_files**: 보관 기간 내 파일(3일 전)이 있을 때 `cleanup_old_backups()` 호출 시 해당 파일이 삭제되지 않고 `deleted_count=0`이 반환되는지 확인

---

## 5. 이메일 본문 - 성공 케이스

- [ ] **test_backup_email_body_success**: 백업 성공 결과로 `send_backup_result_email()` 호출 시 Gmail API `send()`가 호출되고 메시지 ID가 반환되는지 확인

---

## 6. 이메일 본문 - 실패 케이스

- [ ] **test_backup_email_body_failure**: 백업 실패 결과로 `send_backup_result_email()` 호출 시 이메일 본문에 에러 내용('Connection refused')이 포함되는지 확인
