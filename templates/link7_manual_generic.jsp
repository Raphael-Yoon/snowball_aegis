<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - {{ config.name }} - 운영평가</title>
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>

    <!-- 저장 성공 토스트 메시지 -->
    <div id="saveToast" style="position: fixed; top: 20px; right: 20px; z-index: 9999; display: none;">
        <div class="alert alert-success d-flex align-items-center" role="alert" style="box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            <i class="fas fa-check-circle me-2"></i>
            <div>저장되었습니다.</div>
        </div>
    </div>

    <div class="container mt-4">
        <div class="row mb-4">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h2><i class="fas fa-edit me-2"></i>{{ control_name }}</h2>
                    </div>
                    <div class="d-flex gap-2">
                        <button type="button" class="btn btn-outline-warning" id="resetBtn" onclick="resetUpload()" style="display: none;">
                            <i class="fas fa-rotate-right me-1"></i>처음부터
                        </button>
                        <button type="button" class="btn btn-outline-secondary" onclick="goBack()">
                            <i class="fas fa-arrow-left me-1"></i>돌아가기
                        </button>
                    </div>
                </div>
                <hr>
            </div>
        </div>

        <div class="row mb-4">
            <div class="col-12">
                <div class="card border-success">
                    <div class="card-header bg-success text-white">
                        <h5><i class="fas fa-info-circle me-2"></i>통제 정보</h5>
                    </div>
                    <div class="card-body">
                        <strong>통제코드:</strong> {{ control_code }} &nbsp;|&nbsp;
                        <strong>통제명:</strong> {{ control_name }}
                    </div>
                </div>
            </div>
        </div>

        <!-- 당기 발생사실 없음 옵션 -->
        <div class="row mb-4" id="noOccurrenceSection">
            <div class="col-12">
                <div class="card border-warning">
                    <div class="card-header bg-warning text-dark">
                        <h5><i class="fas fa-exclamation-triangle me-2"></i>통제 발생 여부</h5>
                    </div>
                    <div class="card-body">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="noOccurrenceCheckbox" onchange="toggleNoOccurrence()">
                            <label class="form-check-label" for="noOccurrenceCheckbox">
                                <strong>당기 발생사실 없음</strong>
                            </label>
                        </div>
                        <small class="text-muted d-block mt-2">
                            <i class="fas fa-info-circle me-1"></i>
                            해당 통제활동이 평가 기간 동안 발생하지 않은 경우 체크하세요
                        </small>

                        <!-- 비고 입력란 (발생사실 없음 체크 시 표시) -->
                        <div id="noOccurrenceReasonSection" class="mt-3" style="display: none;">
                            <label for="noOccurrenceReason" class="form-label fw-bold">비고 (선택사항)</label>
                            <textarea class="form-control" id="noOccurrenceReason" rows="3" placeholder="필요한 경우 추가 설명을 입력하세요&#10;예) 당기 중 신규 직원 채용이 없었음, 시스템 변경이 발생하지 않았음 등"></textarea>
                            <div class="form-text">
                                <small class="text-muted">
                                    <i class="fas fa-info-circle me-1"></i>
                                    발생하지 않은 이유가 명확하거나 추가 설명이 필요한 경우에만 입력하세요
                                </small>
                            </div>
                            <button type="button" class="btn btn-success mt-2" id="saveNoOccurrenceBtn" onclick="saveNoOccurrence(event)">
                                <i class="fas fa-save me-1"></i>저장
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 설계평가 결과로 대체 옵션 -->
        <div class="row mb-4" id="useDesignEvaluationSection">
            <div class="col-12">
                <div class="card border-info">
                    <div class="card-header bg-info text-white">
                        <h5><i class="fas fa-clipboard-check me-2"></i>설계평가 결과로 대체</h5>
                    </div>
                    <div class="card-body">
                        <button type="button" class="btn btn-info" onclick="applyDesignEvaluation()">설계평가 결과 가져오기</button>
                        <small class="text-muted d-block mt-2">설계평가에서 이미 증빙을 확인한 경우, 해당 내용을 가져와 운영평가를 대체할 수 있습니다.</small>
                    </div>
                </div>
            </div>
        </div>

        {% if not config.get('skip_upload') %}
        <div class="row mb-4" id="step1">
            <div class="col-12">
                <div class="card">
                    <div class="card-header bg-primary text-white">
                        <h5><i class="fas fa-upload me-2"></i>Step 1: 모집단 업로드</h5>
                    </div>
                    <div class="card-body">
                        <div id="uploadFormSection">
                            <div class="alert alert-info">
                                <strong>필수 컬럼:</strong> {{ ', '.join(config.population_headers) }}
                            </div>

                            <div class="mb-3">
                                <label class="form-label">모집단 엑셀 파일</label>
                                <input type="file" class="form-control" id="populationFile" accept=".xlsx,.xls" onchange="readExcelHeaders()">
                            </div>

                            <div id="fieldMappingSection" class="mb-3" style="display: none;">
                                <label class="form-label mb-2">필드 매핑 (엑셀 컬럼을 선택하세요)</label>
                                <div style="overflow-x: auto; border: 1px solid #dee2e6;">
                                    <table class="table table-sm table-bordered mb-0" style="table-layout: fixed; min-width: {{ config.population_fields|length * 250 }}px;">
                                        <thead>
                                            <tr>
                                                {% for label in config.field_labels %}
                                                <th style="width: 250px;">{{ label }}</th>
                                                {% endfor %}
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr>
                                                {% for i in range(config.population_fields|length) %}
                                                <td><select class="form-select form-select-sm" id="col{{ i }}" style="width: 100%;"></select></td>
                                                {% endfor %}
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <button type="button" class="btn btn-primary" id="uploadBtn" onclick="uploadPopulation()" style="display: none;">
                                <i class="fas fa-upload me-1"></i>업로드 및 표본 추출
                            </button>
                        </div>

                        <div id="uploadResult" style="display: none;">
                            <div class="alert alert-success mb-0">
                                <strong><i class="fas fa-check-circle me-2"></i>업로드 완료!</strong><br>
                                모집단: <span id="populationCount">0</span>건 | 표본: <span id="sampleCount">0</span>건
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        {% endif %}

        <div class="row mb-4" id="step2" style="display: none;">
            <div class="col-12">
                <div class="card">
                    <div class="card-header bg-warning text-dark d-flex justify-content-between align-items-center">
                        <h5 class="mb-0"><i class="fas fa-edit me-2"></i>Step 2: 테스트 결과 입력</h5>
                        <button type="button" id="saveResultsBtn" class="btn btn-dark btn-sm" onclick="console.log('[DEBUG] 저장 버튼 클릭됨'); saveResults();">
                            <i class="fas fa-save me-1"></i>저장
                        </button>
                    </div>
                    <div class="card-body">
                        <div style="overflow-x: auto;">
                            <table class="table table-sm table-bordered" style="min-width: 2000px;">
                                <thead class="table-light">
                                    <tr id="tableHeader"></tr>
                                </thead>
                                <tbody id="sampleTable"></tbody>
                            </table>
                        </div>

                        <!-- 결론 섹션 -->
                        <div class="mt-4">
                            <div class="card">
                                <div class="card-header bg-info text-white">
                                    <h6 class="mb-0"><i class="fas fa-chart-pie me-2"></i>테스트 결론</h6>
                                </div>
                                <div class="card-body">
                                    <div class="row">
                                        <div class="col-md-3">
                                            <div class="text-center p-3 border rounded">
                                                <h6 class="text-muted">전체 표본</h6>
                                                <h3 id="totalSamples" class="text-primary mb-0">0</h3>
                                            </div>
                                        </div>
                                        <div class="col-md-3">
                                            <div class="text-center p-3 border rounded">
                                                <h6 class="text-muted">정상</h6>
                                                <h3 id="normalCount" class="text-success mb-0">0</h3>
                                            </div>
                                        </div>
                                        <div class="col-md-3">
                                            <div class="text-center p-3 border rounded">
                                                <h6 class="text-muted">예외</h6>
                                                <h3 id="exceptionCount" class="text-danger mb-0">0</h3>
                                            </div>
                                        </div>
                                        <div class="col-md-3">
                                            <div class="text-center p-3 border rounded">
                                                <h6 class="text-muted">정상률</h6>
                                                <h3 id="normalRate" class="text-info mb-0">0%</h3>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
    <script>
        // 설정 데이터 (서버에서 전달)
        const config = {{ config | tojson | safe }};
        const rcmId = {{ rcm_id }};
        const controlCode = '{{ control_code }}';
        const designEvaluationSession = '{{ design_evaluation_session }}';
        const attributeMeta = {{ attribute_meta | tojson | safe }};

        let samples = [];
        let excelHeaders = [];

        // 기존 운영평가 데이터
        const existingData = {{ existing_data | tojson | safe if existing_data else 'null' }};
        const pc01Data = {{ pc01_data | tojson | safe if pc01_data else 'null' }};

        document.addEventListener('DOMContentLoaded', function() {
            console.log('=== DOMContentLoaded - existingData ===');
            console.log('existingData:', existingData);

            buildTableHeader();

            if (existingData) {
                console.log('existingData.no_occurrence:', existingData.no_occurrence);
                console.log('existingData.no_occurrence_reason:', existingData.no_occurrence_reason);

                loadExistingData();

                // 당기 발생사실 없음 체크 여부 확인
                if (existingData.no_occurrence) {
                    console.log('당기 발생사실 없음 데이터 발견! 체크박스 설정 중...');

                    const checkbox = document.getElementById('noOccurrenceCheckbox');
                    const reasonTextarea = document.getElementById('noOccurrenceReason');

                    if (checkbox) {
                        checkbox.checked = true;
                        console.log('체크박스 체크 완료');
                    } else {
                        console.error('noOccurrenceCheckbox 엘리먼트를 찾을 수 없습니다!');
                    }

                    if (reasonTextarea && existingData.no_occurrence_reason) {
                        reasonTextarea.value = existingData.no_occurrence_reason;
                        console.log('사유 입력란 설정 완료:', existingData.no_occurrence_reason);
                    }

                    // 체크박스 상태에 따라 화면 업데이트
                    toggleNoOccurrence();
                } else {
                    console.log('no_occurrence 데이터가 없거나 false입니다');
                }
            } else {
                console.log('existingData가 null 또는 undefined입니다');
            }
        });

        function buildTableHeader() {
            const headerRow = document.getElementById('tableHeader');
            let html = '';
            
            // 고정 컬럼 (No, 모집단 필드)
            html += '<th style="position: sticky; left: 0; background-color: #f8f9fa; z-index: 10; min-width: 50px; border-right: 2px solid #dee2e6;">No</th>';

            let leftPos = 50;
            config.population_headers.forEach((header, i) => {
                const width = 150; // 기본 너비
                const isLast = (i === config.population_headers.length - 1);
                const borderStyle = isLast ? 'border-right: 2px solid #dee2e6;' : '';
                html += `<th style="position: sticky; left: ${leftPos}px; background-color: #f8f9fa; z-index: 10; min-width: ${width}px; ${borderStyle}">${header}</th>`;
                leftPos += width;
            });

            // 동적 속성 컬럼 (메타데이터 기반)
            attributeMeta.forEach(meta => {
                html += `<th style="min-width: 180px;">${meta.attribute_label}</th>`;
            });

            headerRow.innerHTML = html;
        }

        function loadExistingData() {
            // samples_data 구조에서 데이터 추출
            const samplesData = existingData.samples_data || {};
            samples = samplesData.samples || [];

            if (!config.skip_upload) {
                document.getElementById('uploadFormSection').style.display = 'none';
                document.getElementById('uploadResult').style.display = 'block';
                document.getElementById('populationCount').textContent = samplesData.population_count || 0;
                document.getElementById('sampleCount').textContent = samplesData.sample_size || 0;
            }

            // 처음부터 버튼 표시
            document.getElementById('resetBtn').style.display = 'inline-block';
            document.getElementById('step2').style.display = 'block';

            // 모집단 데이터가 있으면 "당기 발생사실 없음" 섹션 숨기기
            if (samples && samples.length > 0) {
                document.getElementById('noOccurrenceSection').style.display = 'none';
            }

            populateTable();
        }

        function loadPC01Data() {
            // PC02용: PC01 데이터에서 표본 가져오기
            const pc01SamplesData = pc01Data.samples_data || {};
            samples = pc01SamplesData.samples || [];

            document.getElementById('resetBtn').style.display = 'inline-block';
            document.getElementById('step2').style.display = 'block';

            // PC01 데이터가 있으면 "당기 발생사실 없음" 섹션 숨기기
            if (samples && samples.length > 0) {
                document.getElementById('noOccurrenceSection').style.display = 'none';
            }

            populateTable();
        }

        function readExcelHeaders() {
            const file = document.getElementById('populationFile').files[0];
            if (!file) return;

            const reader = new FileReader();
            reader.onload = function(e) {
                const data = new Uint8Array(e.target.result);
                const workbook = XLSX.read(data, {type: 'array'});
                const sheetName = workbook.SheetNames[0];
                const sheet = workbook.Sheets[sheetName];
                const jsonData = XLSX.utils.sheet_to_json(sheet, {header: 1});

                if (jsonData.length > 0) {
                    excelHeaders = jsonData[0];

                    // 셀렉트 박스 채우기
                    config.population_fields.forEach((field, idx) => {
                        const select = document.getElementById(`col${idx}`);
                        select.innerHTML = '<option value="">선택</option>';
                        excelHeaders.forEach((header, headerIdx) => {
                            const option = document.createElement('option');
                            option.value = headerIdx;
                            option.textContent = header;
                            select.appendChild(option);
                        });
                    });

                    document.getElementById('fieldMappingSection').style.display = 'block';
                    document.getElementById('uploadBtn').style.display = 'inline-block';
                }
            };
            reader.readAsArrayBuffer(file);
        }

        function uploadPopulation() {
            const file = document.getElementById('populationFile').files[0];
            if (!file) {
                alert('파일을 선택하세요.');
                return;
            }

            const formData = new FormData();
            formData.append('population_file', file);
            formData.append('rcm_id', rcmId);
            formData.append('design_evaluation_session', designEvaluationSession);

            const mapping = {};
            config.population_fields.forEach((field, idx) => {
                mapping[field] = document.getElementById(`col${idx}`).value;
            });
            formData.append('field_mapping', JSON.stringify(mapping));

            fetch(`/api/operation-evaluation/manual/${controlCode}/upload-population`, {
                method: 'POST',
                body: formData
            })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    samples = data.samples;
                    document.getElementById('uploadFormSection').style.display = 'none';
                    document.getElementById('uploadResult').style.display = 'block';
                    document.getElementById('resetBtn').style.display = 'inline-block';
                    document.getElementById('populationCount').textContent = data.population_count;
                    document.getElementById('sampleCount').textContent = data.sample_size;
                    document.getElementById('step2').style.display = 'block';
                    // 모집단이 업로드되면 "당기 발생사실 없음" 섹션 숨기기
                    document.getElementById('noOccurrenceSection').style.display = 'none';
                    populateTable();
                } else {
                    alert(data.message);
                }
            })
            .catch(e => {
                alert('오류: ' + e);
            });
        }

        function populateTable() {
            const tbody = document.getElementById('sampleTable');
            tbody.innerHTML = '';

            samples.forEach((sample, idx) => {
                const row = tbody.insertRow();
                const data = sample.data;
                const testResult = existingData?.samples_data?.test_results?.test_results?.[idx] || {};

                let html = '';
                
                // 고정 컬럼 (No, 모집단 데이터)
                html += `<td style="position: sticky; left: 0; background-color: white; z-index: 5; min-width: 50px; border-right: 2px solid #dee2e6;">${idx + 1}</td>`;

                let leftPos = 50;
                config.population_fields.forEach((field, i) => {
                    const value = data[field] || '';
                    const width = 150;
                    const isLast = (i === config.population_fields.length - 1);
                    const borderStyle = isLast ? 'border-right: 2px solid #dee2e6;' : '';
                    html += `<td style="position: sticky; left: ${leftPos}px; background-color: white; z-index: 5; min-width: ${width}px; ${borderStyle}">${value}</td>`;
                    leftPos += width;
                });

                // 동적 속성 컬럼 (메타데이터 기반)
                const attributes = testResult.attributes || {};
                attributeMeta.forEach(meta => {
                    const value = attributes[meta.attribute_name] || '';
                    const inputType = meta.attribute_label.includes('일자') ? 'date' : 'text';
                    html += `<td style="min-width: 180px;"><input type="${inputType}" class="form-control form-control-sm" value="${value}" id="${meta.attribute_name}_${idx}" onchange="checkException(${idx})"></td>`;
                });

                row.innerHTML = html;
            });

            samples.forEach((_, idx) => {
                if (controlCode === 'PC02') {
                    checkExceptionPC02(idx);
                } else if (controlCode === 'PC03') {
                    checkExceptionPC03(idx);
                } else {
                    checkException(idx);
                }
            });

            updateConclusion();
            document.getElementById('step2').scrollIntoView({ behavior: 'smooth' });
        }

        function checkExceptionPC02(idx) {
            // PC02 예외 로직: 사용자테스트 미수행 또는 테스트일자 미입력 또는 테스트일자 > 반영일자
            const testYn = document.getElementById(`test_yn_${idx}`).value;
            const testDate = document.getElementById(`test_date_${idx}`).value;
            const deployDate = samples[idx].data.deploy_date;

            const badge = document.getElementById(`exc_${idx}`);
            const notesField = document.getElementById(`notes_${idx}`);

            let isException = false;
            const reasons = [];

            // 사용자테스트 미수행
            if (testYn !== 'Y') {
                isException = true;
                reasons.push('사용자테스트 미수행');
            }

            // 테스트일자 미입력 (테스트 수행한 경우만 체크)
            if (testYn === 'Y' && !testDate) {
                isException = true;
                reasons.push('테스트일자 미입력');
            }

            // 테스트일자 > 반영일자
            if (testDate && deployDate && new Date(testDate) > new Date(deployDate)) {
                isException = true;
                reasons.push('테스트일자가 반영일자 이후');
            }

            if (isException) {
                badge.textContent = 'Y';
                badge.className = 'badge bg-danger';
                if (!notesField.value.startsWith('[예외사유]')) {
                    notesField.value = '[예외사유] ' + reasons.join(', ');
                }
            } else {
                badge.textContent = 'N';
                badge.className = 'badge bg-success';
                if (notesField.value.startsWith('[예외사유]')) {
                    notesField.value = '';
                }
            }

            updateConclusion();
        }

        function checkExceptionPC03(idx) {
            // PC03 예외 로직: 배포요청자/승인자 누락, 동일인, 부서 상이, 승인일자 비교
            const deployReq = document.getElementById(`deploy_req_${idx}`).value.trim();
            const deployReqDept = document.getElementById(`deploy_req_dept_${idx}`).value.trim();
            const deployAppr = document.getElementById(`deploy_appr_${idx}`).value.trim();
            const deployApprDept = document.getElementById(`deploy_appr_dept_${idx}`).value.trim();
            const deployApprDate = document.getElementById(`deploy_appr_date_${idx}`).value;
            const deployDate = samples[idx].data.deploy_date;

            const badge = document.getElementById(`exc_${idx}`);
            const notesField = document.getElementById(`notes_${idx}`);

            let isException = false;
            const reasons = [];

            // 배포요청자 누락
            if (!deployReq) {
                isException = true;
                reasons.push('배포요청자 누락');
            }

            // 배포승인자 누락
            if (!deployAppr) {
                isException = true;
                reasons.push('배포승인자 누락');
            }

            // 배포승인일자 누락
            if (!deployApprDate) {
                isException = true;
                reasons.push('배포승인일자 누락');
            }

            // 배포요청자와 배포승인자가 동일
            if (deployReq && deployAppr && deployReq === deployAppr) {
                isException = true;
                reasons.push('배포요청자와 배포승인자가 동일');
            }

            // 배포요청자부서와 배포승인자부서가 상이
            if (deployReqDept && deployApprDept && deployReqDept !== deployApprDept) {
                isException = true;
                reasons.push('배포요청자부서와 배포승인자부서가 상이');
            }

            // 배포승인일자 > 반영일자
            if (deployApprDate && deployDate && new Date(deployApprDate) > new Date(deployDate)) {
                isException = true;
                reasons.push('배포승인일자가 반영일자 이후');
            }

            if (isException) {
                badge.textContent = 'Y';
                badge.className = 'badge bg-danger';
                if (!notesField.value.startsWith('[예외사유]')) {
                    notesField.value = '[예외사유] ' + reasons.join(', ');
                }
            } else {
                badge.textContent = 'N';
                badge.className = 'badge bg-success';
                if (notesField.value.startsWith('[예외사유]')) {
                    notesField.value = '';
                }
            }

            updateConclusion();
        }

        function goBack() {
            if (window.parent !== window) {
                window.parent.location.href = '/operation-evaluation/rcm';
            } else {
                window.location.href = '/operation-evaluation/rcm';
            }
        }

        function resetUpload() {
            if (!confirm('처음부터 다시 시작하시겠습니까? 입력한 데이터는 삭제됩니다.')) {
                return;
            }

            fetch('/api/operation-evaluation/reset', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({
                    rcm_id: rcmId,
                    control_code: controlCode,
                    design_evaluation_session: designEvaluationSession
                })
            })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    // PC02의 경우 페이지 새로고침으로 처음 상태로 복원
                    if (config.skip_upload) {
                        location.reload();
                    } else {
                        // 다른 통제들: 기존 로직
                        samples = [];
                        excelHeaders = [];
                        const fileInput = document.getElementById('populationFile');
                        if (fileInput) fileInput.value = '';
                        const fieldMapping = document.getElementById('fieldMappingSection');
                        if (fieldMapping) fieldMapping.style.display = 'none';
                        const uploadBtn = document.getElementById('uploadBtn');
                        if (uploadBtn) uploadBtn.style.display = 'none';
                        const uploadResult = document.getElementById('uploadResult');
                        if (uploadResult) uploadResult.style.display = 'none';
                        const uploadForm = document.getElementById('uploadFormSection');
                        if (uploadForm) uploadForm.style.display = 'block';
                        document.getElementById('resetBtn').style.display = 'none';
                        document.getElementById('step2').style.display = 'none';
                        document.getElementById('sampleTable').innerHTML = '';
                    }
                } else {
                    alert('리셋 오류: ' + data.message);
                }
            })
            .catch(e => {
                alert('리셋 오류: ' + e);
            });
        }

        function checkException(idx) {
            const reqName = document.getElementById(`req_name_${idx}`).value.trim();
            const reqDept = document.getElementById(`req_dept_${idx}`).value.trim();
            const apprName = document.getElementById(`appr_name_${idx}`).value.trim();
            const apprDept = document.getElementById(`appr_dept_${idx}`).value.trim();
            const approvalDate = document.getElementById(`appr_date_${idx}`).value;

            // 마지막 population 필드에서 날짜 가져오기 (grant_date 또는 change_date)
            const lastField = config.population_fields[config.population_fields.length - 1];
            const grantDate = samples[idx].data[lastField];

            const sameDept = reqDept && apprDept && reqDept === apprDept;
            const hasApprover = apprName && apprName.length > 0;
            const hasApprovalDate = approvalDate && approvalDate.length > 0;
            // 날짜 비교: 둘 다 있으면 비교
            let approvalBeforeGrant = true;
            if (approvalDate && grantDate) {
                approvalBeforeGrant = new Date(approvalDate) <= new Date(grantDate);
            }
            const differentPerson = reqName && apprName && reqName !== apprName;

            const isNormal = sameDept && hasApprover && hasApprovalDate && approvalBeforeGrant && differentPerson;

            const badge = document.getElementById(`exc_${idx}`);
            const notesField = document.getElementById(`notes_${idx}`);

            if (isNormal) {
                badge.textContent = 'N';
                badge.className = 'badge bg-success';
                if (notesField.value.startsWith('[예외사유]')) {
                    notesField.value = '';
                }
            } else {
                badge.textContent = 'Y';
                badge.className = 'badge bg-danger';

                const reasons = [];
                if (reqDept && apprDept && !sameDept) reasons.push('요청자부서와 승인자부서가 상이');
                if (!hasApprover) reasons.push('승인자명 누락');
                if (!hasApprovalDate) reasons.push('승인일자 누락');
                if (approvalDate && grantDate && !approvalBeforeGrant) reasons.push('승인일자가 권한부여일자 이후');
                if (reqName && apprName && !differentPerson) reasons.push('요청자와 승인자가 동일');

                if (reasons.length > 0) {
                    notesField.value = '[예외사유] ' + reasons.join(', ');
                }
            }

            updateConclusion();
        }

        function saveResults() {
            try {
                console.log('===== saveResults 함수 호출됨 =====');
                console.log('rcmId:', rcmId);
                console.log('controlCode:', controlCode);
                console.log('designEvaluationSession:', designEvaluationSession);
                console.log('samples 개수:', samples ? samples.length : 0);

                if (!samples || samples.length === 0) {
                    console.error('samples 배열이 비어있거나 정의되지 않았습니다');
                    alert('표본 데이터가 없습니다. 먼저 모집단을 업로드해주세요.');
                    return;
                }

                const results = samples.map((s, i) => {
                    const result = {
                        sample_index: i,
                        population_data: s.data,
                        has_exception: document.getElementById(`exc_${i}`).textContent === 'Y',
                        notes: document.getElementById(`notes_${i}`).value
                    };
                    
                    // 동적 속성 데이터 수집
                    result.attributes = {};
                    attributeMeta.forEach(meta => {
                        const inputEl = document.getElementById(`${meta.attribute_name}_${i}`);
                        result.attributes[meta.attribute_name] = inputEl ? inputEl.value : '';
                    });

                    // 예외 로직은 각 통제별로 checkException 함수에서 처리
                    if (controlCode === 'PC02') {
                        checkExceptionPC02(i);
                    } else if (controlCode === 'PC03') {
                        checkExceptionPC03(i);
                    } else {
                        checkException(i);
                    }

                    return result;
                });

                console.log('수집된 결과 데이터:', results);

                const url = `/api/operation-evaluation/manual/${controlCode}/save-test-results`;
                const payload = {
                    rcm_id: rcmId,
                    control_code: controlCode,
                    design_evaluation_session: designEvaluationSession,
                    test_results: results
                };

                console.log('전송 URL:', url);
                console.log('전송 데이터:', JSON.stringify(payload));

                fetch(url, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(payload)
                })
                .then(response => {
                    console.log('응답 상태:', response.status, response.statusText);
                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status}`);
                    }
                    return response.json();
                })
                .then(data => {
                    console.log('응답 데이터:', data);
                    if (data.success) {
                        console.log('저장 성공!');
                        showToast();
                    } else {
                        console.error('저장 실패:', data.message);
                        alert('저장 실패: ' + (data.message || '알 수 없는 오류'));
                    }
                })
                .catch(error => {
                    console.error('저장 오류:', error);
                    alert('저장 중 오류 발생: ' + error.message);
                });
            } catch (error) {
                console.error('saveResults 함수 실행 중 오류:', error);
                alert('데이터 수집 중 오류 발생: ' + error.message);
            }
        }

        function updateConclusion() {
            const total = samples.length;
            let exceptionCount = 0;

            samples.forEach((_, i) => {
                const exc = document.getElementById(`exc_${i}`);
                if (exc && exc.textContent === 'Y') {
                    exceptionCount++;
                }
            });

            const normalCount = total - exceptionCount;
            const normalRate = total > 0 ? ((normalCount / total) * 100).toFixed(1) : 0;

            document.getElementById('totalSamples').textContent = total;
            document.getElementById('normalCount').textContent = normalCount;
            document.getElementById('exceptionCount').textContent = exceptionCount;
            document.getElementById('normalRate').textContent = normalRate + '%';
        }

        function showToast() {
            const toast = document.getElementById('saveToast');
            toast.style.display = 'block';
            toast.style.opacity = '1';

            setTimeout(() => {
                toast.style.transition = 'opacity 0.5s ease-out';
                toast.style.opacity = '0';

                setTimeout(() => {
                    toast.style.display = 'none';
                }, 500);
            }, 2000);
        }

        // ===================================================================
        // 당기 발생사실 없음 관련 함수
        // ===================================================================

        function toggleNoOccurrence() {
            const checkbox = document.getElementById('noOccurrenceCheckbox');
            const reasonSection = document.getElementById('noOccurrenceReasonSection');
            const step1 = document.getElementById('step1');
            const step2 = document.getElementById('step2');
            const step3 = document.getElementById('step3');

            if (checkbox.checked) {
                // 당기 발생사실 없음 체크 시
                reasonSection.style.display = 'block';

                // 다른 단계들 숨기기
                if (step1) step1.style.display = 'none';
                if (step2) step2.style.display = 'none';
                if (step3) step3.style.display = 'none';
            } else {
                // 체크 해제 시
                reasonSection.style.display = 'none';

                // 다른 단계들 다시 표시
                if (step1) step1.style.display = 'block';
                if (step2) step2.style.display = 'block';
                if (step3) step3.style.display = 'block';
            }
        }

        function saveNoOccurrence(event) {
            try {
                console.log('saveNoOccurrence 함수 호출됨');
                console.log('rcmId:', rcmId);
                console.log('controlCode:', controlCode);
                console.log('designEvaluationSession:', designEvaluationSession);

                // 버튼 가져오기
                const saveBtn = event ? event.target : document.getElementById('saveNoOccurrenceBtn');
                if (!saveBtn) {
                    console.error('저장 버튼을 찾을 수 없습니다');
                    return;
                }

                const reasonElement = document.getElementById('noOccurrenceReason');
                if (!reasonElement) {
                    console.error('noOccurrenceReason 엘리먼트를 찾을 수 없습니다');
                    alert('입력 필드를 찾을 수 없습니다.');
                    return;
                }

                const reason = reasonElement.value.trim();

                const data = {
                    rcm_id: rcmId,
                    control_code: controlCode,
                    design_evaluation_session: designEvaluationSession,
                    no_occurrence: true,
                    no_occurrence_reason: reason
                };

                console.log('전송할 데이터:', data);

                // 버튼 비활성화
                saveBtn.disabled = true;
                saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>저장 중...';

                fetch('/api/operation-evaluation/save-no-occurrence', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                })
                .then(response => {
                    console.log('응답 상태:', response.status);
                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status}`);
                    }
                    return response.json();
                })
                .then(result => {
                    console.log('응답 데이터:', result);
                    if (result.success) {
                        // 토스트 표시
                        showToast();

                        // 0.5초 후 팝업 닫기 또는 새로고침
                        setTimeout(() => {
                            try {
                                // 팝업 창으로 열렸는지 확인
                                if (window.opener) {
                                    // 팝업 창이면 부모 창 새로고침 후 닫기
                                    window.opener.location.reload();
                                    window.close();
                                } else if (window.parent !== window) {
                                    // iframe 안에 있으면 부모 창 새로고침
                                    window.parent.postMessage({ type: 'reload' }, '*');
                                    setTimeout(() => {
                                        window.location.reload();
                                    }, 1000);
                                } else {
                                    // 일반 페이지면 현재 창 새로고침
                                    window.location.reload();
                                }
                            } catch (e) {
                                console.error('새로고침 오류:', e);
                                window.location.reload();
                            }
                        }, 500);
                    } else {
                        saveBtn.disabled = false;
                        saveBtn.innerHTML = '<i class="fas fa-save me-1"></i>저장';
                        alert('저장 실패: ' + (result.message || '알 수 없는 오류'));
                    }
                })
                .catch(error => {
                    console.error('저장 오류:', error);
                    saveBtn.disabled = false;
                    saveBtn.innerHTML = '<i class="fas fa-save me-1"></i>저장';
                    alert('저장 중 오류가 발생했습니다: ' + error.message);
                });
            } catch (error) {
                console.error('saveNoOccurrence 함수 실행 오류:', error);
                alert('함수 실행 오류: ' + error.message);
            }
        }
    </script>
</body>
</html>
