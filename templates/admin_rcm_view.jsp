<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - RCM 상세보기</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        #rcmTable {
            table-layout: auto; /* 내용에 따라 너비 자동 조정 */
            min-width: 1200px;  /* 테이블의 최소 너비 설정 */
        }
        #rcmTable th, #rcmTable td {
            word-wrap: break-word;
            overflow-wrap: break-word;
            vertical-align: top;
            white-space: normal; /* 자동 줄바꿈 허용 */
        }
        .text-truncate-custom {
            display: block;
        }
        /* 숫자 입력 필드의 스피너(화살표) 제거 */
        input[type=number]::-webkit-inner-spin-button,
        input[type=number]::-webkit-outer-spin-button {
            -webkit-appearance: none;
            margin: 0;
        }
        input[type=number] {
            -moz-appearance: textfield;
        }
    </style>
</head>
<body>
    {% include 'navi.jsp' %}

    <!-- 토스트 컨테이너 -->
    <div class="toast-container position-fixed top-0 end-0 p-3" style="z-index: 1100;">
        <div id="saveToast" class="toast" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="toast-header">
                <i class="fas fa-info-circle me-2 toast-icon"></i>
                <strong class="me-auto toast-title">알림</strong>
                <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
            <div class="toast-body">
            </div>
        </div>
    </div>

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h1><i class="fas fa-eye me-2"></i>RCM 상세보기</h1>
                    <div>
                        <a href="/admin/rcm/{{ rcm_info.token }}/users" class="btn btn-success me-2">
                            <i class="fas fa-users me-1"></i>사용자 관리
                        </a>
                        <a href="/admin/rcm" class="btn btn-secondary">
                            <i class="fas fa-arrow-left me-1"></i>목록으로
                        </a>
                    </div>
                </div>
                <hr>
            </div>
        </div>

        <!-- RCM 기본 정보 -->
        <div class="row mb-4">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-info-circle me-2"></i>RCM 기본 정보</h5>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6">
                                <table class="table table-borderless">
                                    <tr>
                                        <th width="30%">RCM명:</th>
                                        <td><strong>{{ rcm_info.rcm_name }}</strong></td>
                                    </tr>
                                    <tr>
                                        <th>회사명:</th>
                                        <td>{{ rcm_info.company_name }}</td>
                                    </tr>
                                    <tr>
                                        <th>설명:</th>
                                        <td>{{ rcm_info.description or '없음' }}</td>
                                    </tr>
                                </table>
                            </div>
                            <div class="col-md-6">
                                <table class="table table-borderless">
                                    <tr>
                                        <th width="30%">소유자:</th>
                                        <td>{{ rcm_info.owner_name or '알 수 없음' }}</td>
                                    </tr>
                                    <tr>
                                        <th>업로드일:</th>
                                        <td>{{ rcm_info.upload_date.split(' ')[0] if rcm_info.upload_date else '-' }}</td>
                                    </tr>
                                    <tr>
                                        <th>총 통제 수:</th>
                                        <td><span class="badge bg-primary">{{ rcm_details|length }}개</span></td>
                                    </tr>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- RCM 상세 데이터 -->
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5><i class="fas fa-list me-2"></i>통제 상세 목록</h5>
                        <div>
                            <button class="btn btn-sm btn-outline-primary me-2" id="saveAllSampleSizesBtn" onclick="saveAllSampleSizes()">
                                <i class="fas fa-save me-1"></i>저장
                            </button>
                            <button class="btn btn-sm btn-outline-secondary" onclick="exportToExcel()">
                                <i class="fas fa-file-excel me-1"></i>Excel 다운로드
                            </button>
                        </div>
                    </div>
                    <div class="card-body">
                        {% if rcm_details %}
                        <div class="table-responsive">
                            <table class="table table-striped table-hover" id="rcmTable">
                                <thead>
                                    <tr>
                                        <th width="6%">통제코드</th>
                                        <th width="10%">통제명</th>
                                        <th width="17%">통제활동설명</th>
                                        <th width="7%">통제주기</th>
                                        <th width="7%">통제유형</th>
                                        <th width="7%">통제구분</th>
                                        <th width="6%">핵심통제</th>
                                        <th width="10%">모집단</th>
                                        <th width="13%">테스트절차</th>
                                        <th width="7%">권장표본수</th>
                                        <th width="10%">Attribute 설정</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for detail in rcm_details %}
                                    <tr>
                                        <td><code>{{ detail.control_code }}</code></td>
                                        <td>
                                            <span class="text-truncate-custom" title="{{ detail.control_name }}">
                                                <strong>{{ detail.control_name }}</strong>
                                            </span>
                                        </td>
                                        <td>
                                            {% if detail.control_description %}
                                                <span class="text-truncate-custom" title="{{ detail.control_description }}">
                                                    {{ detail.control_description }}
                                                </span>
                                            {% else %}
                                                <span class="text-muted">-</span>
                                            {% endif %}
                                        </td>
                                        <td>
                                            <span class="text-truncate-custom" title="{{ detail.control_frequency_name or detail.control_frequency or '-' }}">
                                                {{ detail.control_frequency_name or detail.control_frequency or '-' }}
                                            </span>
                                        </td>
                                        <td>
                                            <span class="text-truncate-custom" title="{{ detail.control_type_name or detail.control_type or '-' }}">
                                                {{ detail.control_type_name or detail.control_type or '-' }}
                                            </span>
                                        </td>
                                        <td>
                                            <span class="text-truncate-custom" title="{{ detail.control_nature_name or detail.control_nature or '-' }}">
                                                {{ detail.control_nature_name or detail.control_nature or '-' }}
                                            </span>
                                        </td>
                                        <td class="text-center">
                                            {% if detail.key_control == '핵심' %}
                                                <span class="badge bg-danger">핵심</span>
                                            {% elif detail.key_control == '비핵심' %}
                                                <span class="badge bg-secondary">비핵심</span>
                                            {% else %}
                                                <span class="badge bg-warning">미설정</span>
                                            {% endif %}
                                        </td>
                                        <td>
                                            <span class="text-truncate-custom" title="{{ detail.population or '-' }}">
                                                {{ detail.population or '-' }}
                                            </span>
                                        </td>
                                        <td>
                                            {% if detail.test_procedure %}
                                                <span class="text-truncate-custom" title="{{ detail.test_procedure }}">
                                                    {{ detail.test_procedure }}
                                                </span>
                                            {% else %}
                                                <span class="text-muted">-</span>
                                            {% endif %}
                                        </td>
                                        <td class="text-center">
                                            <input type="number"
                                                   class="form-control form-control-sm text-center sample-size-input"
                                                   data-detail-id="{{ detail.detail_id if detail.detail_id is not none else '' }}"
                                                   data-control-code="{{ detail.control_code }}"
                                                   data-control-frequency="{{ detail.control_frequency or '' }}"
                                                   data-original-value="{{ detail.recommended_sample_size or '' }}"
                                                   value="{{ detail.recommended_sample_size or '' }}"
                                                   min="1"
                                                   max="100"
                                                   placeholder="자동"
                                                   style="width: 60px;">
                                        </td>
                                        <td class="text-center">
                                            <button class="btn btn-sm btn-outline-primary"
                                                    onclick="openAttributeModal('{{ detail.detail_id }}', '{{ detail.control_code }}', '{{ detail.control_name }}')">
                                                <i class="fas fa-cog me-1"></i>설정
                                            </button>
                                            <div id="attribute-summary-{{ detail.detail_id }}" class="mt-1 small text-muted">
                                                {% set attr_count = 0 %}
                                                {% for i in range(10) %}
                                                    {% if detail['attribute' ~ i] %}
                                                        {% set attr_count = attr_count + 1 %}
                                                    {% endif %}
                                                {% endfor %}
                                                {% if attr_count > 0 %}
                                                    <span class="badge bg-info">{{ attr_count }}개 설정됨</span>
                                                {% endif %}
                                            </div>
                                        </td>
                                    </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                        {% else %}
                        <div class="text-center py-5">
                            <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                            <h5 class="text-muted">등록된 통제 데이터가 없습니다</h5>
                            <p class="text-muted">Excel 파일을 업로드하여 통제 데이터를 추가해주세요.</p>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Attribute 설정 모달 -->
    <div class="modal fade" id="attributeModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-cog me-2"></i>Attribute 설정
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <strong>통제코드:</strong> <code id="modal-control-code"></code><br>
                        <strong>통제명:</strong> <span id="modal-control-name"></span>
                    </div>
                    <hr>
                    <div class="alert alert-info">
                        <i class="fas fa-info-circle me-2"></i>
                        모집단과 증빙 항목으로 사용할 attribute 필드를 설정하세요.
                    </div>
                    <div class="mb-3">
                        <label for="population-attr-count" class="form-label">
                            <strong>모집단 항목 수</strong>
                            <small class="text-muted">(attribute0부터 시작, 나머지는 증빙 항목)</small>
                        </label>
                        <input type="number"
                               class="form-control form-control-sm"
                               id="population-attr-count"
                               min="0"
                               max="10"
                               value="2"
                               style="width: 100px;"
                               placeholder="예: 2">
                        <small class="text-muted">
                            예: 2로 설정 시 attribute0~1은 모집단, attribute2~9는 증빙
                        </small>
                    </div>
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th width="20%">Attribute</th>
                                <th width="80%">필드명</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for i in range(10) %}
                            <tr>
                                <td><strong>attribute{{ i }}</strong></td>
                                <td>
                                    <input type="text"
                                           class="form-control form-control-sm attribute-input"
                                           id="attr-input-{{ i }}"
                                           data-index="{{ i }}"
                                           placeholder="예: 완료예정일, 완료여부, 승인자 등"
                                           maxlength="100">
                                </td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i>취소
                    </button>
                    <button type="button" class="btn btn-primary" onclick="saveAttributes()">
                        <i class="fas fa-save me-1"></i>저장
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Excel 다운로드 기능
        function exportToExcel() {
            const table = document.getElementById('rcmTable');
            if (!table) {
                alert('다운로드할 데이터가 없습니다.');
                return;
            }
            
            let csv = '';
            const rows = table.querySelectorAll('tr');
            
            for (let i = 0; i < rows.length; i++) {
                const cols = rows[i].querySelectorAll('td, th');
                const rowData = [];
                
                for (let j = 0; j < cols.length; j++) {
                    let cellData = cols[j].textContent.trim();
                    // CSV용 특수문자 처리
                    cellData = cellData.replace(/"/g, '""');
                    if (cellData.includes(',') || cellData.includes('"') || cellData.includes('\n')) {
                        cellData = '"' + cellData + '"';
                    }
                    rowData.push(cellData);
                }
                csv += rowData.join(',') + '\n';
            }
            
            // BOM 추가 (한글 깨짐 방지)
            const bom = '\uFEFF';
            const csvContent = bom + csv;
            
            // 다운로드
            const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            const link = document.createElement('a');
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', '{{ rcm_info.rcm_name }}_통제목록.csv');
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        // 통제주기에 따른 기본 표본수 계산
        function getDefaultSampleSize(controlFrequency) {
            if (!controlFrequency) return 1;
            const frequencyCode = controlFrequency.charAt(0).toUpperCase();
            const frequencyMapping = {
                'A': 1,  // 연간
                'Q': 2,  // 분기
                'M': 2,  // 월
                'W': 5,  // 주
                'D': 20, // 일
                'O': 1,  // 기타
                'N': 1   // 필요시
            };
            return frequencyMapping[frequencyCode] || 1;
        }

        // 토스트 메시지 표시 함수
        function showToast(message, type = 'info') {
            const toastEl = document.getElementById('saveToast');
            const toastBody = toastEl.querySelector('.toast-body');
            const toastHeader = toastEl.querySelector('.toast-header');
            const toastIcon = toastEl.querySelector('.toast-icon');
            const toastTitle = toastEl.querySelector('.toast-title');

            // 메시지 설정
            toastBody.textContent = message;

            // 타입에 따른 스타일 및 아이콘 설정
            toastHeader.className = 'toast-header';
            toastIcon.className = 'me-2 toast-icon';

            if (type === 'success') {
                toastHeader.classList.add('bg-success', 'text-white');
                toastIcon.classList.add('fas', 'fa-check-circle');
                toastTitle.textContent = '성공';
            } else if (type === 'error') {
                toastHeader.classList.add('bg-danger', 'text-white');
                toastIcon.classList.add('fas', 'fa-exclamation-circle');
                toastTitle.textContent = '오류';
            } else if (type === 'warning') {
                toastHeader.classList.add('bg-warning');
                toastIcon.classList.add('fas', 'fa-exclamation-triangle');
                toastTitle.textContent = '경고';
            } else {
                toastHeader.classList.add('bg-info', 'text-white');
                toastIcon.classList.add('fas', 'fa-info-circle');
                toastTitle.textContent = '알림';
            }

            // 토스트 표시
            const toast = new bootstrap.Toast(toastEl, {
                autohide: true,
                delay: 3000
            });
            toast.show();
        }

        // 일괄 저장 기능
        function saveAllSampleSizes() {
            const saveBtn = document.getElementById('saveAllSampleSizesBtn');
            const inputs = document.querySelectorAll('.sample-size-input');

            console.log(`[DEBUG] 총 ${inputs.length}개의 입력 필드 발견`);

            // 변경된 항목만 수집
            const changes = [];
            inputs.forEach((input, index) => {
                const detailId = input.getAttribute('data-detail-id');
                const originalValue = input.getAttribute('data-original-value') || '';
                // number 타입 입력 필드의 경우 valueAsNumber도 확인
                const currentValue = input.value || '';
                const currentValueNum = input.valueAsNumber;

                console.log(`[DEBUG ${index}] detail_id: ${detailId}, originalValue: "${originalValue}", currentValue: "${currentValue}", valueAsNumber: ${currentValueNum}`);

                // detail_id 유효성 검증
                if (!detailId || detailId === 'None' || detailId === 'null' || detailId.trim() === '') {
                    console.error(`[DEBUG ${index}] 유효하지 않은 detail_id:`, detailId);
                    return; // 이 항목은 건너뛰기
                }

                // 값 정규화 (빈 문자열과 null을 동일하게 처리)
                // 원본 값: 빈 문자열이면 null, 아니면 문자열 그대로
                const normalizedOriginal = originalValue.trim() === '' ? null : originalValue.trim();
                // 현재 값: 빈 문자열이면 null, 숫자면 숫자 문자열로, 아니면 문자열 그대로
                let normalizedCurrent;
                if (currentValue.trim() === '') {
                    normalizedCurrent = null;
                } else if (!isNaN(currentValueNum) && currentValueNum !== 0) {
                    // 유효한 숫자인 경우 문자열로 변환 (일관성 유지)
                    normalizedCurrent = String(currentValueNum);
                } else {
                    normalizedCurrent = currentValue.trim();
                }

                // 값이 변경된 경우만 추가
                if (normalizedOriginal !== normalizedCurrent) {
                    console.log(`[변경 감지 ${index}] detail_id: ${detailId}, 원본: "${normalizedOriginal}", 현재: "${normalizedCurrent}"`);
                    changes.push({
                        detail_id: detailId,
                        sample_size: normalizedCurrent ? parseInt(normalizedCurrent) : null
                    });
                } else {
                    console.log(`[변경 없음 ${index}] detail_id: ${detailId}, 원본: "${normalizedOriginal}", 현재: "${normalizedCurrent}"`);
                }
            });

            console.log(`[DEBUG] 총 ${changes.length}개의 변경사항 발견`);

            if (changes.length === 0) {
                showToast('변경된 항목이 없습니다.', 'info');
                return;
            }

            // 버튼 비활성화 및 로딩 표시
            const originalHtml = saveBtn.innerHTML;
            saveBtn.disabled = true;
            saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>저장 중...';

            // 모든 변경사항을 순차적으로 저장
            let successCount = 0;
            let failCount = 0;
            const promises = changes.map(change => {
                return fetch(`/admin/rcm/detail/${change.detail_id}/sample-size`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        recommended_sample_size: change.sample_size
                    })
                })
                .then(response => {
                    // 응답 상태 확인
                    if (!response.ok) {
                        // 에러 응답 처리
                        return response.text().then(text => {
                            try {
                                // JSON으로 파싱 시도
                                return JSON.parse(text);
                            } catch (e) {
                                // JSON이 아니면 에러 메시지 반환
                                return {
                                    success: false,
                                    message: `서버 오류 (${response.status}): ${response.statusText}`
                                };
                            }
                        });
                    }
                    return response.json();
                })
                .then(data => {
                    if (data.success) {
                        successCount++;
                        // 저장 성공 시 original-value 업데이트
                        const input = document.querySelector(`.sample-size-input[data-detail-id="${change.detail_id}"]`);
                        if (input) {
                            input.setAttribute('data-original-value', change.sample_size || '');
                        }
                    } else {
                        failCount++;
                        console.error('저장 실패:', data.message || '알 수 없는 오류');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    failCount++;
                });
            });

            Promise.all(promises).then(() => {
                // 결과 표시
                if (failCount === 0) {
                    // 모두 성공
                    saveBtn.classList.remove('btn-outline-primary');
                    saveBtn.classList.add('btn-success');
                    saveBtn.innerHTML = '<i class="fas fa-check me-1"></i>저장 완료';

                    showToast(`${successCount}개 항목이 성공적으로 저장되었습니다.`, 'success');

                    setTimeout(() => {
                        saveBtn.classList.remove('btn-success');
                        saveBtn.classList.add('btn-outline-primary');
                        saveBtn.innerHTML = originalHtml;
                        saveBtn.disabled = false;
                    }, 2000);
                } else {
                    // 일부 실패
                    showToast(`저장 완료: ${successCount}개 성공, ${failCount}개 실패`, 'warning');
                    saveBtn.innerHTML = originalHtml;
                    saveBtn.disabled = false;
                }
            });
        }

        // Attribute 설정 모달 관련 변수
        let currentDetailId = null;
        let attributeModalInstance = null;

        // Attribute 모달 열기
        function openAttributeModal(detailId, controlCode, controlName) {
            currentDetailId = detailId;

            // 모달 정보 표시
            document.getElementById('modal-control-code').textContent = controlCode;
            document.getElementById('modal-control-name').textContent = controlName;

            // 기존 attribute 값 로드
            loadAttributes(detailId);

            // 모달 표시
            const modalEl = document.getElementById('attributeModal');
            if (!attributeModalInstance) {
                attributeModalInstance = new bootstrap.Modal(modalEl);
            }
            attributeModalInstance.show();
        }

        // 기존 attribute 값 로드
        function loadAttributes(detailId) {
            fetch(`/admin/rcm/detail/${detailId}/attributes`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const attributes = data.attributes || {};

                        // attribute 필드 로드
                        for (let i = 0; i < 10; i++) {
                            const input = document.getElementById(`attr-input-${i}`);
                            if (input) {
                                input.value = attributes[`attribute${i}`] || '';
                            }
                        }

                        // population_attribute_count 로드
                        const popCountInput = document.getElementById('population-attr-count');
                        if (popCountInput) {
                            // 0도 유효한 값이므로 null/undefined만 체크
                            popCountInput.value = data.population_attribute_count !== null && data.population_attribute_count !== undefined ? data.population_attribute_count : 2;
                        }
                    } else {
                        console.error('Failed to load attributes:', data.message);
                    }
                })
                .catch(error => {
                    console.error('Error loading attributes:', error);
                });
        }

        // Attribute 저장
        function saveAttributes() {
            if (!currentDetailId) {
                showToast('오류: 통제 ID가 없습니다.', 'error');
                return;
            }

            // attribute 값 수집
            const attributes = {};
            for (let i = 0; i < 10; i++) {
                const input = document.getElementById(`attr-input-${i}`);
                if (input && input.value.trim()) {
                    attributes[`attribute${i}`] = input.value.trim();
                }
            }

            // population_attribute_count 수집
            const popCountInput = document.getElementById('population-attr-count');
            const populationAttributeCount = popCountInput ? parseInt(popCountInput.value) : 2;

            // 서버에 저장
            fetch(`/admin/rcm/detail/${currentDetailId}/attributes`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    attributes,
                    population_attribute_count: populationAttributeCount
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showToast('Attribute 설정이 저장되었습니다.', 'success');

                    // 모달 닫기
                    if (attributeModalInstance) {
                        attributeModalInstance.hide();
                    }

                    // 요약 업데이트
                    updateAttributeSummary(currentDetailId, attributes);
                } else {
                    showToast('저장 실패: ' + (data.message || '알 수 없는 오류'), 'error');
                }
            })
            .catch(error => {
                console.error('Error saving attributes:', error);
                showToast('저장 중 오류가 발생했습니다.', 'error');
            });
        }

        // Attribute 요약 업데이트
        function updateAttributeSummary(detailId, attributes) {
            const summaryEl = document.getElementById(`attribute-summary-${detailId}`);
            if (!summaryEl) return;

            const count = Object.keys(attributes).length;
            if (count > 0) {
                summaryEl.innerHTML = `<span class="badge bg-info">${count}개 설정됨</span>`;
            } else {
                summaryEl.innerHTML = '';
            }
        }

        // 권장 표본수 초기화
        document.addEventListener('DOMContentLoaded', function() {
            // 툴팁 초기화
            var tooltipTriggerList = [].slice.call(document.querySelectorAll('[title]'));
            var tooltipList = tooltipTriggerList.map(function(tooltipTriggerEl) {
                return new bootstrap.Tooltip(tooltipTriggerEl);
            });

            // 각 입력란의 placeholder를 자동 계산된 값으로 설정
            document.querySelectorAll('.sample-size-input').forEach(input => {
                if (!input.value) {
                    const controlFrequency = input.getAttribute('data-control-frequency');
                    const defaultSize = getDefaultSampleSize(controlFrequency);
                    input.setAttribute('placeholder', defaultSize);
                }
            });
        });
    </script>
</body>
</html>