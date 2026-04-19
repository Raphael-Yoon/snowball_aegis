<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - RCM 컬럼 매핑</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .auto-mapped {
            border-left: 4px solid #28a745 !important;
            background-color: #f8fff9 !important;
        }
        .preview-area {
            max-height: 150px;
            overflow-y: auto;
        }
    </style>
</head>
<body>
    {% include 'navi.jsp' %}

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <h1><i class="fas fa-columns me-2"></i>컬럼 매핑</h1>
                <p class="text-muted">Excel 파일의 컬럼을 시스템 필드와 매핑해주세요.</p>
                <hr>
            </div>
        </div>

        <div class="row">
            <div class="col-12">
                <div class="card mb-4">
                    <div class="card-header">
                        <h5><i class="fas fa-info-circle me-2"></i>RCM 정보</h5>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6">
                                <p><strong>RCM명:</strong> {{ rcm_info.rcm_name }}</p>
                                <p><strong>설명:</strong> {{ rcm_info.description or '없음' }}</p>
                            </div>
                            <div class="col-md-6">
                                <p><strong>총 데이터 행:</strong> {{ total_rows }}개</p>
                                <p><strong>업로드일:</strong> {{ rcm_info.upload_date.split(' ')[0] if rcm_info.upload_date else '-' }}</p>
                            </div>
                        </div>
                        <div class="row mt-3">
                            <div class="col-md-6">
                                <label for="headerRow" class="form-label"><strong>헤더 행 선택:</strong></label>
                                <select class="form-select" id="headerRow" name="header_row">
                                    <option value="1">1번째 행 (기본값)</option>
                                    <option value="2">2번째 행</option>
                                    <option value="3">3번째 행</option>
                                    <option value="4">4번째 행</option>
                                    <option value="5">5번째 행</option>
                                </select>
                                <div class="form-text">
                                    <i class="fas fa-info-circle me-1"></i>
                                    컬럼명이 있는 행을 선택하세요.
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <form id="mappingForm">
            <input type="hidden" name="rcm_id" value="{{ rcm_info.rcm_id }}">
            
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h5><i class="fas fa-exchange-alt me-2"></i>컬럼 매핑 설정</h5>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-bordered">
                                    <thead>
                                        <tr>
                                            <th width="25%">시스템 필드</th>
                                            <th width="25%">Excel 컬럼 선택</th>
                                            <th width="50%">미리보기</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {% for field in system_fields %}
                                        <tr>
                                            <td>
                                                <strong>{{ field.name }}</strong>
                                                {% if field.required %}
                                                <span class="text-danger">*</span>
                                                {% endif %}
                                                <br>
                                                <small class="text-muted">{{ field.key }}</small>
                                                {% if field.description %}
                                                <br>
                                                <small class="text-info"><i class="fas fa-info-circle me-1"></i>{{ field.description }}</small>
                                                {% endif %}
                                            </td>
                                            <td>
                                                <select class="form-select mapping-select" 
                                                        name="mapping_{{ field.key }}" 
                                                        data-field="{{ field.key }}"
                                                        {% if field.required %}required{% endif %}>
                                                    <option value="">선택 안함</option>
                                                    {% for header in headers %}
                                                    <option value="{{ loop.index0 }}">{{ header or '(빈 컬럼 ' + loop.index|string + ')' }}</option>
                                                    {% endfor %}
                                                </select>
                                            </td>
                                            <td>
                                                <div id="preview_{{ field.key }}" class="preview-area text-muted">
                                                    컬럼을 선택하면 미리보기가 표시됩니다.
                                                </div>
                                            </td>
                                        </tr>
                                        {% endfor %}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row mt-4">
                <div class="col-12">
                    <div class="alert alert-info">
                        <i class="fas fa-lightbulb me-2"></i>
                        <strong>매핑 안내:</strong>
                        <ul class="mb-0 mt-2">
                            <li><span class="text-danger">빨간 별표(*)</span>가 있는 필드는 필수 매핑 항목입니다.</li>
                            <li>하나의 Excel 컬럼을 여러 시스템 필드에 매핑할 수 있습니다.</li>
                            <li>매핑하지 않은 필드는 빈 값으로 저장됩니다.</li>
                        </ul>
                    </div>
                </div>
            </div>

            <div class="row mt-4">
                <div class="col-12 d-flex justify-content-between">
                    <a href="/admin/rcm" class="btn btn-secondary">
                        <i class="fas fa-arrow-left me-2"></i>취소
                    </a>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save me-2"></i>매핑 완료 및 저장
                    </button>
                </div>
            </div>
        </form>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // 샘플 데이터와 자동 매핑 결과
        const sampleData = {{ sample_data | safe }};
        const autoMapping = {{ auto_mapping | safe }};
        let currentHeaderRow = 1; // 현재 선택된 헤더 행
        let currentHeaders = sampleData[0] || []; // 현재 헤더
        
        // 페이지 로드 시 자동 매핑 적용
        document.addEventListener('DOMContentLoaded', function() {
            let autoMappedCount = 0;
            
            // 자동 매핑 적용
            Object.keys(autoMapping).forEach(fieldKey => {
                const columnIndex = autoMapping[fieldKey];
                const select = document.querySelector(`select[data-field="${fieldKey}"]`);
                
                if (select) {
                    select.value = columnIndex;
                    // 미리보기 업데이트
                    updatePreview(fieldKey, columnIndex);
                    // 자동 매핑된 항목에 스타일 추가
                    select.classList.add('auto-mapped');
                    autoMappedCount++;
                }
            });
            
            // 자동 매핑 결과 알림
            if (autoMappedCount > 0) {
                const alertDiv = document.createElement('div');
                alertDiv.className = 'alert alert-success alert-dismissible fade show mt-3';
                alertDiv.innerHTML = `
                    <i class="fas fa-magic me-2"></i>
                    <strong>자동 매핑 완료!</strong> ${autoMappedCount}개 필드가 컬럼명을 기반으로 자동 매핑되었습니다.
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                `;
                document.querySelector('.card-body').insertBefore(alertDiv, document.querySelector('.table-responsive'));
            }
        });
        
        // 헤더 행 변경 처리
        document.getElementById('headerRow').addEventListener('change', function() {
            const newHeaderRow = parseInt(this.value);
            currentHeaderRow = newHeaderRow;
            
            // 새로운 헤더 추출
            if (sampleData.length >= newHeaderRow) {
                currentHeaders = sampleData[newHeaderRow - 1] || [];
            } else {
                currentHeaders = [];
            }
            
            // 모든 컬럼 선택 드롭다운 업데이트
            updateColumnOptions();
            
            // 모든 미리보기 업데이트
            document.querySelectorAll('.mapping-select').forEach(select => {
                const fieldKey = select.getAttribute('data-field');
                const columnIndex = select.value;
                updatePreview(fieldKey, columnIndex);
            });
        });
        
        // 컬럼 옵션 업데이트 함수
        function updateColumnOptions() {
            document.querySelectorAll('.mapping-select').forEach(select => {
                const currentValue = select.value;
                select.innerHTML = '<option value="">선택 안함</option>';
                
                currentHeaders.forEach((header, index) => {
                    const option = document.createElement('option');
                    option.value = index;
                    option.textContent = header || `(빈 컬럼 ${index + 1})`;
                    select.appendChild(option);
                });
                
                // 이전 선택값이 유효하면 유지
                if (currentValue && currentValue < currentHeaders.length) {
                    select.value = currentValue;
                }
            });
        }
        
        // 미리보기 업데이트 함수
        function updatePreview(fieldKey, columnIndex) {
            const previewDiv = document.getElementById('preview_' + fieldKey);
            
            if (columnIndex === '' || columnIndex === null) {
                previewDiv.innerHTML = '<span class="text-muted">컬럼을 선택하면 미리보기가 표시됩니다.</span>';
            } else {
                const colIndex = parseInt(columnIndex);
                let previewHtml = '<small>';
                
                // 헤더 행 이후의 데이터만 미리보기에 표시
                sampleData.forEach((row, index) => {
                    // 현재 헤더 행 이후의 데이터만 표시
                    if (index >= currentHeaderRow) {
                        const value = row[colIndex] || '';
                        const dataRowNumber = index - currentHeaderRow + 1;
                        previewHtml += `<div class="mb-1"><span class="badge bg-light text-dark me-1">${dataRowNumber}</span>${value}</div>`;
                    }
                });
                
                previewHtml += '</small>';
                previewDiv.innerHTML = previewHtml;
            }
        }
        
        // 컬럼 선택 시 미리보기 업데이트
        document.querySelectorAll('.mapping-select').forEach(select => {
            select.addEventListener('change', function() {
                const fieldKey = this.getAttribute('data-field');
                const columnIndex = this.value;
                updatePreview(fieldKey, columnIndex);
                
                // 수동 변경 시 자동 매핑 스타일 제거
                this.classList.remove('auto-mapped');
            });
        });

        // 폼 제출
        document.getElementById('mappingForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            const submitBtn = document.querySelector('button[type="submit"]');
            
            // 필수 필드 체크
            let missingRequired = [];
            document.querySelectorAll('.mapping-select[required]').forEach(select => {
                if (!select.value) {
                    const fieldName = select.closest('tr').querySelector('strong').textContent;
                    missingRequired.push(fieldName);
                }
            });
            
            if (missingRequired.length > 0) {
                alert('[ADMIN-001] 다음 필수 필드를 매핑해주세요:\\n' + missingRequired.join(', '));
                return;
            }
            
            // 버튼 비활성화
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>저장 중...';
            
            fetch('/admin/rcm/save_mapping', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('[ADMIN-002] RCM 데이터가 성공적으로 저장되었습니다!');
                    window.location.href = '/admin/rcm';
                } else {
                    alert('[ADMIN-003] 저장 실패: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('[ADMIN-004] 저장 중 오류가 발생했습니다.');
            })
            .finally(() => {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fas fa-save me-2"></i>매핑 완료 및 저장';
            });
        });
    </script>
</body>
</html>