<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>Snowball - 작업 로그 관리</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .log-content {
            white-space: pre-wrap;
            font-family: 'Courier New', Courier, monospace;
            font-size: 0.9rem;
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            border: 1px solid #dee2e6;
        }

        .date-badge {
            font-size: 0.85rem;
            font-weight: 600;
        }
    </style>
</head>

<body>
    {% include 'navi.jsp' %}

    <div class="container mt-4">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h1><i class="fas fa-file-alt me-2"></i>작업 로그 관리</h1>
            <div>
                {% if doc_url %}
                <a href="{{ doc_url }}" target="_blank" class="btn btn-outline-primary me-2">
                    <i class="fas fa-file-word me-1"></i>Google Docs 열기
                </a>
                {% endif %}
                <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addLogModal">
                    <i class="fas fa-plus me-1"></i>새 로그 작성
                </button>
            </div>
        </div>

        <div class="card mb-4">
            <div class="card-header bg-light d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><i class="fas fa-history me-2"></i>작업 내역</h5>
                <button class="btn btn-sm btn-outline-warning" onclick="migrateWorkLog()">
                    <i class="fas fa-file-import me-1"></i>WORK_LOG.md 마이그레이션 (Docs)
                </button>
            </div>
            <div class="card-body">
                <div class="text-center py-5">
                    <i class="fas fa-file-alt fa-3x text-muted mb-3"></i>
                    <p class="text-muted">상세 작업 로그는 Google Docs에서 확인하실 수 있습니다.</p>
                    {% if doc_url %}
                    <a href="{{ doc_url }}" target="_blank" class="btn btn-primary">
                        <i class="fas fa-external-link-alt me-1"></i>Google Docs에서 전체 보기
                    </a>
                    {% endif %}
                </div>
            </div>
        </div>
    </div>

    <!-- 새 로그 작성 모달 -->
    <div class="modal fade" id="addLogModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">새 작업 로그 작성</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="addLogForm">
                        <div class="mb-3">
                            <label class="form-label">작업 내용</label>
                            <textarea class="form-control" id="log_entry" rows="10"
                                placeholder="작업 내용을 입력하세요..."></textarea>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
                    <button type="button" class="btn btn-primary" onclick="saveWorkLog()">저장</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function saveWorkLog() {
            const logEntry = document.getElementById('log_entry').value;
            if (!logEntry.trim()) {
                alert('내용을 입력해주세요.');
                return;
            }

            fetch('/api/work-log', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': '{{ csrf_token() if csrf_token else "" }}'
                },
                body: JSON.stringify({ log_entry: logEntry })
            })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('로그가 저장되었습니다.');
                        location.reload();
                    } else {
                        alert('저장 실패: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('오류가 발생했습니다.');
                });
        }

        function migrateWorkLog() {
            if (!confirm('WORK_LOG.md 파일의 내용을 Google Sheets로 마이그레이션하시겠습니까?\n(이미 존재하는 항목은 중복될 수 있습니다.)')) {
                return;
            }

            const btn = event.target;
            const originalText = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>처리 중...';

            fetch('/admin/work-log/migrate', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': '{{ csrf_token() if csrf_token else "" }}'
                }
            })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert(data.message);
                        location.reload();
                    } else {
                        alert('마이그레이션 실패: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('오류가 발생했습니다.');
                })
                .finally(() => {
                    btn.disabled = false;
                    btn.innerHTML = originalText;
                });
        }
    </script>
</body>

</html>