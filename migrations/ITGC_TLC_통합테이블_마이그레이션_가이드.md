# ITGC/TLC 통합 테이블 마이그레이션 가이드

## 개요
ITGC와 TLC를 ELC와 동일하게 통합 테이블(`sb_evaluation_header`, `sb_evaluation_line`, `sb_evaluation_sample`)로 마이그레이션

**기존 구조**:
- 설계평가: `sb_design_evaluation_header`, `sb_design_evaluation_line`
- 운영평가: `sb_operation_evaluation_header`, `sb_operation_evaluation_line`

**신규 구조**:
- 통합: `sb_evaluation_header`, `sb_evaluation_line`, `sb_evaluation_sample`
- 하나의 header/line 레코드가 설계평가 + 운영평가 데이터 모두 포함

---

## 1. 데이터베이스 마이그레이션

### 1.1 설계평가 데이터 마이그레이션
**파일**: `migrations/migrate_itgc_tlc_design_to_unified.py`

```python
"""
ITGC/TLC 설계평가 데이터를 통합 테이블로 마이그레이션
sb_design_evaluation_header/line → sb_evaluation_header/line
"""
import sys
sys.path.insert(0, 'c:/Pythons/snowball')
from db_config import get_db

with get_db() as conn:
    # 1. ITGC/TLC 설계평가 헤더 조회
    headers = conn.execute('''
        SELECT h.*, r.control_category
        FROM sb_design_evaluation_header h
        INNER JOIN sb_rcm r ON h.rcm_id = r.rcm_id
        WHERE r.control_category IN ('ITGC', 'TLC')
    ''').fetchall()

    for header in headers:
        hd = dict(header)

        # 2. 통합 테이블에 헤더 생성
        conn.execute('''
            INSERT INTO sb_evaluation_header (
                rcm_id, evaluation_name, status, created_at, last_updated, archived
            ) VALUES (?, ?, ?, ?, ?, 0)
        ''', (
            hd['rcm_id'],
            hd['evaluation_session'],
            1 if hd['progress'] == 100 else 0,  # progress 100 = 완료
            hd['created_at'],
            hd['last_updated']
        ))

        new_header_id = conn.execute('SELECT last_insert_rowid()').fetchone()[0]

        # 3. 라인 데이터 복사
        lines = conn.execute('''
            SELECT * FROM sb_design_evaluation_line
            WHERE header_id = ?
        ''', (hd['header_id'],)).fetchall()

        for line in lines:
            ld = dict(line)
            conn.execute('''
                INSERT INTO sb_evaluation_line (
                    header_id, control_code,
                    overall_effectiveness, evaluation_rationale,
                    improvement_suggestion, evaluation_evidence,
                    design_comment, last_updated
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                new_header_id,
                ld['control_code'],
                ld['overall_effectiveness'],
                ld['evaluation_rationale'],
                ld['improvement_suggestion'],
                ld['evaluation_evidence'],
                ld['design_comment'],
                ld['last_updated']
            ))

        # 4. 설계평가 샘플 데이터 복사 (있는 경우)
        # sb_design_evaluation_sample 테이블이 있다면 여기서 처리

    conn.commit()
    print("ITGC/TLC 설계평가 마이그레이션 완료")
```

### 1.2 운영평가 데이터 마이그레이션
**파일**: `migrations/migrate_itgc_tlc_operation_to_unified.py`

```python
"""
ITGC/TLC 운영평가 데이터를 통합 테이블로 마이그레이션
sb_operation_evaluation_header/line → sb_evaluation_header/line
"""
import sys
sys.path.insert(0, 'c:/Pythons/snowball')
from db_config import get_db

with get_db() as conn:
    # 1. ITGC/TLC 운영평가 헤더 조회
    op_headers = conn.execute('''
        SELECT h.*, r.control_category
        FROM sb_operation_evaluation_header h
        INNER JOIN sb_rcm r ON h.rcm_id = r.rcm_id
        WHERE r.control_category IN ('ITGC', 'TLC')
    ''').fetchall()

    for op_header in op_headers:
        ohd = dict(op_header)

        # 2. 해당 설계평가 세션의 통합 헤더 찾기
        unified_header = conn.execute('''
            SELECT header_id FROM sb_evaluation_header
            WHERE rcm_id = ? AND evaluation_name = ?
        ''', (ohd['rcm_id'], ohd['design_evaluation_session'])).fetchone()

        if not unified_header:
            print(f"[SKIP] 설계평가 헤더 없음: {ohd['design_evaluation_session']}")
            continue

        unified_header_id = dict(unified_header)['header_id']

        # 3. 운영평가 데이터를 통합 라인에 업데이트
        op_lines = conn.execute('''
            SELECT * FROM sb_operation_evaluation_line
            WHERE header_id = ?
        ''', (ohd['header_id'],)).fetchall()

        for op_line in op_lines:
            old = dict(op_line)

            # 통합 라인 업데이트
            conn.execute('''
                UPDATE sb_evaluation_line
                SET sample_size = ?,
                    exception_count = ?,
                    mitigating_factors = ?,
                    exception_details = ?,
                    conclusion = ?,
                    improvement_plan = ?,
                    no_occurrence = ?,
                    no_occurrence_reason = ?,
                    use_design_evaluation = ?,
                    last_updated = ?
                WHERE header_id = ? AND control_code = ?
            ''', (
                old.get('sample_size', 0),
                old.get('exception_count', 0),
                old.get('mitigating_factors', ''),
                old.get('exception_details', ''),
                old.get('conclusion', ''),
                old.get('improvement_plan', ''),
                old.get('no_occurrence', 0),
                old.get('no_occurrence_reason', ''),
                old.get('use_design_evaluation', 0),
                old.get('last_updated'),
                unified_header_id,
                old['control_code']
            ))

        # 4. 헤더 status 업데이트 (운영평가 완료 = status 4)
        progress = ohd.get('progress_percentage', 0)
        if progress >= 100:
            conn.execute('''
                UPDATE sb_evaluation_header
                SET status = 4
                WHERE header_id = ?
            ''', (unified_header_id,))
        elif progress > 0:
            conn.execute('''
                UPDATE sb_evaluation_header
                SET status = 3
                WHERE header_id = ?
            ''', (unified_header_id,))

    conn.commit()
    print("ITGC/TLC 운영평가 마이그레이션 완료")
```

---

## 2. 백엔드 코드 수정 (auth.py)

### 2.1 설계평가 저장 함수 수정

**함수**: `save_design_evaluation()`

**현재 (ITGC/TLC)**:
```python
# sb_design_evaluation_header, sb_design_evaluation_line 사용
```

**수정 후**:
```python
def save_design_evaluation(...):
    # RCM category 확인
    rcm_info = conn.execute('SELECT control_category FROM sb_rcm WHERE rcm_id = ?', (rcm_id,)).fetchone()
    control_category = dict(rcm_info)['control_category']

    # 모든 카테고리에서 통합 테이블 사용
    # (ELC, ITGC, TLC 모두 동일)
    _save_design_evaluation_unified(...)
```

### 2.2 운영평가 저장 함수 수정

**함수**: `save_operation_evaluation()`

**현재**:
```python
if control_category == 'ELC':
    _save_operation_evaluation_unified(...)
else:
    # ITGC/TLC는 기존 테이블 사용
```

**수정 후**:
```python
# 모든 카테고리에서 통합 테이블 사용
_save_operation_evaluation_unified(...)
```

### 2.3 핵심통제 조회 함수 수정

**함수**: `get_key_rcm_details()`

**현재**:
```python
if rcm_category == 'ELC':
    # sb_evaluation_header/line 사용
else:
    # sb_design_evaluation_header/line 사용 (ITGC/TLC)
```

**수정 후**:
```python
# 모든 카테고리에서 통합 테이블 사용
query = '''
    SELECT DISTINCT d.*, l.evaluation_evidence, l.design_comment, h.header_id
    FROM sb_rcm_detail_v d
    INNER JOIN sb_evaluation_header h ON d.rcm_id = h.rcm_id
    INNER JOIN sb_evaluation_line l ON h.header_id = l.header_id AND d.control_code = l.control_code
    WHERE d.rcm_id = ?
        AND (d.key_control = 'Y' OR d.key_control = '핵심' OR d.key_control = 'KEY')
        AND h.evaluation_name = ?
        AND l.overall_effectiveness IN ('적정', 'effective', '효과적')
        AND h.archived = 0
'''
```

### 2.4 완료된 설계평가 세션 조회 함수 수정

**함수**: `get_completed_design_evaluation_sessions()`

**현재**:
```python
if control_category == 'ELC':
    # sb_evaluation_header 사용
else:
    # sb_design_evaluation_header 사용 (ITGC/TLC)
```

**수정 후**:
```python
# 모든 카테고리에서 통합 테이블 사용
sessions = conn.execute('''
    SELECT header_id, evaluation_name as evaluation_session,
           created_at, last_updated
    FROM sb_evaluation_header
    WHERE rcm_id = ?
    AND status >= 1
    AND archived = 0
    ORDER BY created_at DESC
''', (rcm_id,)).fetchall()
```

### 2.5 운영평가 데이터 조회 함수 수정

**함수**: `get_operation_evaluations()`

**현재**:
```python
if control_category == 'ELC':
    # 통합 테이블 사용
else:
    # ITGC: 기존 테이블 사용
    query = '''SELECT l.*, h.design_evaluation_session, h.evaluation_session
               FROM sb_operation_evaluation_line l
               JOIN sb_operation_evaluation_header h ...'''
```

**수정 후**:
```python
# 모든 카테고리에서 통합 테이블 사용
query = '''
    SELECT l.*, h.evaluation_name
    FROM sb_evaluation_line l
    JOIN sb_evaluation_header h ON l.header_id = h.header_id
    WHERE h.rcm_id = ? AND h.evaluation_name = ?
    ORDER BY l.control_code
'''
```

---

## 3. 프론트엔드 코드 수정

### 3.1 ITGC 운영평가 페이지 (snowball_link7.py)

**라우트**: `/operation-evaluation`, `/tlc-operation-evaluation`

**수정 필요 부분**:
1. `get_key_rcm_details()` 호출 시 `control_category` 파라미터 제거 (자동 감지)
2. 설계평가 세션 조회 로직 통합 테이블 기준으로 변경

### 3.2 설계평가 목록 페이지 수정

**변경 사항**:
- `sb_design_evaluation_header` → `sb_evaluation_header`
- `progress` 컬럼 → `status` 컬럼 기준으로 완료 여부 판단
- `progress = 100` → `status >= 1`

---

## 4. 테이블 스키마 확인

### 4.1 통합 테이블 스키마

```sql
-- sb_evaluation_header
CREATE TABLE sb_evaluation_header (
    header_id INTEGER PRIMARY KEY AUTOINCREMENT,
    rcm_id INTEGER NOT NULL,
    evaluation_name TEXT NOT NULL,  -- 평가명 (기존 evaluation_session)
    status INTEGER DEFAULT 0,        -- 0=설계진행중, 1=설계완료, 3=운영진행중, 4=운영완료
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived INTEGER DEFAULT 0,      -- 0=활성, 1=아카이브
    UNIQUE(rcm_id, evaluation_name)
);

-- sb_evaluation_line
CREATE TABLE sb_evaluation_line (
    line_id INTEGER PRIMARY KEY AUTOINCREMENT,
    header_id INTEGER NOT NULL,
    control_code TEXT NOT NULL,

    -- 설계평가 필드
    overall_effectiveness TEXT,      -- '적정', 'effective', '효과적', 등
    evaluation_rationale TEXT,
    improvement_suggestion TEXT,
    evaluation_evidence TEXT,
    design_comment TEXT,

    -- 운영평가 필드
    sample_size INTEGER DEFAULT 0,
    exception_count INTEGER DEFAULT 0,
    mitigating_factors TEXT,
    exception_details TEXT,
    conclusion TEXT,                 -- 'effective' 또는 'exception'
    improvement_plan TEXT,
    no_occurrence INTEGER DEFAULT 0,
    no_occurrence_reason TEXT,
    use_design_evaluation INTEGER DEFAULT 0,

    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (header_id) REFERENCES sb_evaluation_header(header_id),
    UNIQUE(header_id, control_code)
);

-- sb_evaluation_sample
CREATE TABLE sb_evaluation_sample (
    sample_id INTEGER PRIMARY KEY AUTOINCREMENT,
    line_id INTEGER NOT NULL,
    sample_number INTEGER NOT NULL,
    evaluation_type TEXT NOT NULL,   -- 'design' 또는 'operation'
    evidence TEXT,
    has_exception INTEGER DEFAULT 0,
    mitigation TEXT,

    -- Attribute 필드 (0~9)
    attribute0 TEXT,
    attribute1 TEXT,
    attribute2 TEXT,
    attribute3 TEXT,
    attribute4 TEXT,
    attribute5 TEXT,
    attribute6 TEXT,
    attribute7 TEXT,
    attribute8 TEXT,
    attribute9 TEXT,

    FOREIGN KEY (line_id) REFERENCES sb_evaluation_line(line_id),
    UNIQUE(line_id, sample_number, evaluation_type)
);
```

---

## 5. 마이그레이션 실행 순서

1. **백업**
   ```bash
   python migrations/backup_database.py
   ```

2. **설계평가 마이그레이션**
   ```bash
   python migrations/migrate_itgc_tlc_design_to_unified.py
   ```

3. **운영평가 마이그레이션**
   ```bash
   python migrations/migrate_itgc_tlc_operation_to_unified.py
   ```

4. **데이터 검증**
   ```bash
   python migrations/verify_itgc_tlc_migration.py
   ```

5. **백엔드 코드 수정** (auth.py)

6. **프론트엔드 코드 수정** (snowball_link7.py)

7. **테스트**
   - ITGC 설계평가 생성/조회/수정
   - ITGC 운영평가 생성/조회/수정
   - TLC 설계평가 생성/조회/수정
   - TLC 운영평가 생성/조회/수정

8. **구 테이블 삭제** (선택사항)
   ```sql
   DROP TABLE sb_design_evaluation_line;
   DROP TABLE sb_design_evaluation_header;
   DROP TABLE sb_operation_evaluation_line;
   DROP TABLE sb_operation_evaluation_header;
   ```

---

## 6. 주의사항

### 6.1 user_id 처리
- 기존 ITGC/TLC는 `user_id` 기반
- 통합 테이블은 `rcm_id` 기반 (user_id 없음)
- 마이그레이션 시 user_id 정보는 evaluation_name에 포함하거나 별도 관리 필요

### 6.2 evaluation_session vs evaluation_name
- 기존: `evaluation_session` (ITGC/TLC)
- 통합: `evaluation_name` (ELC)
- 컬럼명 통일 필요

### 6.3 진행률 계산
- 기존 ITGC/TLC: `progress` 컬럼 (0-100)
- 통합: `status` 컬럼 (0, 1, 3, 4)
- 진행률은 동적 계산: `calculate_design_progress()`, `calculate_operation_progress()`

### 6.4 샘플 데이터
- ITGC/TLC에 기존 샘플 데이터가 있다면 `sb_evaluation_sample` 테이블로 마이그레이션
- `evaluation_type='design'` 또는 `'operation'`으로 구분

---

## 7. 검증 스크립트

**파일**: `migrations/verify_itgc_tlc_migration.py`

```python
"""
ITGC/TLC 마이그레이션 검증
"""
import sys
sys.path.insert(0, 'c:/Pythons/snowball')
from db_config import get_db

with get_db() as conn:
    # 1. 통합 테이블 레코드 수 확인
    unified_headers = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_evaluation_header h
        INNER JOIN sb_rcm r ON h.rcm_id = r.rcm_id
        WHERE r.control_category IN ('ITGC', 'TLC')
    ''').fetchone()

    print(f"통합 헤더: {dict(unified_headers)['count']}개")

    # 2. 기존 테이블 레코드 수 확인
    old_design_headers = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_design_evaluation_header h
        INNER JOIN sb_rcm r ON h.rcm_id = r.rcm_id
        WHERE r.control_category IN ('ITGC', 'TLC')
    ''').fetchone()

    print(f"기존 설계평가 헤더: {dict(old_design_headers)['count']}개")

    # 3. 데이터 일치 확인
    # ...
```

---

## 8. 롤백 계획

마이그레이션 실패 시:

1. 백업 파일 복원
   ```bash
   python migrations/restore_database.py
   ```

2. 코드 변경사항 되돌리기
   ```bash
   git checkout auth.py snowball_link7.py
   ```

---

## 9. 완료 후 체크리스트

- [ ] 설계평가 데이터 마이그레이션 완료
- [ ] 운영평가 데이터 마이그레이션 완료
- [ ] 샘플 데이터 마이그레이션 완료 (해당 시)
- [ ] auth.py 코드 수정 완료
- [ ] snowball_link7.py 코드 수정 완료
- [ ] ITGC 설계평가 테스트 통과
- [ ] ITGC 운영평가 테스트 통과
- [ ] TLC 설계평가 테스트 통과
- [ ] TLC 운영평가 테스트 통과
- [ ] 기존 데이터 검증 완료
- [ ] 구 테이블 삭제 (선택)
