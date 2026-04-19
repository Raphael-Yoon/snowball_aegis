<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - RCM 업로드</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
    {% include 'navi.jsp' %}

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <h1><i class="fas fa-upload me-2"></i>새 RCM 업로드</h1>
                <hr>
            </div>
        </div>

        <div class="row justify-content-center">
            <div class="col-lg-8">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-file-excel me-2"></i>RCM 파일 업로드</h5>
                    </div>
                    <div class="card-body">
                        <form id="rcmUploadForm" enctype="multipart/form-data">
                            <div class="mb-3">
                                <label for="rcmName" class="form-label">RCM 명 <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="rcmName" name="rcm_name" required 
                                       placeholder="예: ABC회사 2024년 RCM">
                            </div>
                            
                            <div class="mb-3">
                                <label for="targetUser" class="form-label">대상 사용자 (회사) <span class="text-danger">*</span></label>
                                <select class="form-select" id="targetUser" name="target_user_id" required>
                                    <option value="">사용자를 선택하세요</option>
                                    {% for user in users %}
                                    <option value="{{ user.user_id }}">{{ user.company_name }} - {{ user.user_name }} ({{ user.user_email }})</option>
                                    {% endfor %}
                                </select>
                                <div class="form-text">
                                    <i class="fas fa-info-circle me-1"></i>
                                    RCM이 속할 회사의 사용자를 선택하세요.
                                </div>
                            </div>
                            
                            <div class="mb-3">
                                <label for="description" class="form-label">설명</label>
                                <textarea class="form-control" id="description" name="description" rows="3" 
                                          placeholder="RCM에 대한 간단한 설명을 입력하세요"></textarea>
                            </div>
                            
                            <div class="mb-4">
                                <label for="excelFile" class="form-label">Excel 파일 <span class="text-danger">*</span></label>
                                <input type="file" class="form-control" id="excelFile" name="excel_file" 
                                       accept=".xlsx,.xls" required>
                                <div class="form-text">
                                    <i class="fas fa-info-circle me-1"></i>
                                    Excel 파일(.xlsx, .xls)만 업로드 가능합니다.
                                </div>
                            </div>
                            
                            <div class="alert alert-info">
                                <i class="fas fa-lightbulb me-2"></i>
                                <strong>안내사항:</strong>
                                <ul class="mb-0 mt-2">
                                    <li>Excel 파일의 첫 번째 행은 헤더로 인식됩니다.</li>
                                    <li>업로드 후 각 컬럼을 시스템 필드와 매핑하는 과정이 진행됩니다.</li>
                                    <li>필수 필드: 통제코드, 통제명</li>
                                    <li>권장 필드: 통제활동설명, 핵심통제여부, 통제주기, 통제유형 등</li>
                                </ul>
                            </div>
                            
                            <div class="d-grid gap-2 d-md-flex justify-content-md-end">
                                <a href="/admin/rcm" class="btn btn-secondary">
                                    <i class="fas fa-arrow-left me-2"></i>취소
                                </a>
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-cloud-upload-alt me-2"></i>업로드 및 매핑
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.getElementById('rcmUploadForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            const submitBtn = document.querySelector('button[type="submit"]');
            
            // 버튼 비활성화 및 로딩 표시
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>업로드 중...';
            
            fetch('/admin/rcm/process_upload', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    window.location.href = `/admin/rcm/mapping/${data.rcm_id}`;
                } else {
                    alert('[ADMIN-007] 업로드 실패: ' + data.message);
                    submitBtn.disabled = false;
                    submitBtn.innerHTML = '<i class="fas fa-cloud-upload-alt me-2"></i>업로드 및 매핑';
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('[ADMIN-008] 업로드 중 오류가 발생했습니다.');
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fas fa-cloud-upload-alt me-2"></i>업로드 및 매핑';
            });
        });
    </script>
</body>
</html>