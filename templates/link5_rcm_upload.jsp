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
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h1><i class="fas fa-upload me-2"></i>RCM 업로드</h1>
            <a href="{{ url_for('link5.user_rcm') }}" class="btn btn-outline-secondary">
                <i class="fas fa-arrow-left me-1"></i>목록으로
            </a>
        </div>

        <div class="card">
            <div class="card-body">
                <form id="rcmUploadForm" enctype="multipart/form-data">
                    <div class="mb-3">
                        <label for="rcm_name" class="form-label">RCM 이름 <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="rcm_name" name="rcm_name" required>
                    </div>

                    <div class="mb-3">
                        <label for="control_category" class="form-label">통제 카테고리 <span class="text-danger">*</span></label>
                        <select class="form-select" id="control_category" name="control_category" required>
                            <option value="ELC">ELC - Entity Level Controls (전사적 통제)</option>
                            <option value="TLC">TLC - Transaction Level Controls (거래 수준 통제)</option>
                            <option value="ITGC" selected>ITGC - IT General Controls (IT 일반 통제)</option>
                        </select>
                    </div>

                    <div class="mb-3">
                        <label for="description" class="form-label">설명</label>
                        <textarea class="form-control" id="description" name="description" rows="3"></textarea>
                    </div>

                    <div class="mb-3">
                        <label for="rcm_file" class="form-label">Excel 파일 <span class="text-danger">*</span></label>
                        <input type="file" class="form-control" id="rcm_file" name="rcm_file" accept=".xlsx,.xls" required>
                        <div class="form-text">
                            <i class="fas fa-info-circle me-1"></i>
                            .xlsx 또는 .xls 형식의 Excel 파일만 업로드 가능합니다.
                        </div>
                        <!-- 로딩 인디케이터 -->
                        <div id="fileLoadingIndicator" style="display: none;" class="mt-3">
                            <div class="card border-info">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="spinner-border spinner-border-sm text-info me-3" role="status">
                                            <span class="visually-hidden">Loading...</span>
                                        </div>
                                        <div>
                                            <strong id="loadingStatusText">파일을 읽고 있습니다...</strong>
                                            <div class="small text-muted mt-1">잠시만 기다려주세요.</div>
                                        </div>
                                    </div>
                                    <div class="progress mt-3" style="height: 5px;">
                                        <div class="progress-bar progress-bar-striped progress-bar-animated bg-info"
                                             role="progressbar" style="width: 100%"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 헤더 행 선택 -->
                    <div class="mb-3" id="headerRowContainer" style="display: none;">
                        <label for="header_row" class="form-label">
                            <i class="fas fa-heading me-1"></i>헤더 행 (컬럼명이 있는 행)
                        </label>
                        <input type="number" class="form-control" id="header_row" name="header_row" value="0" min="0" max="9">
                        <div class="form-text">
                            <i class="fas fa-info-circle me-1"></i>
                            컬럼명(헤더)이 있는 행 번호를 입력하세요 (0부터 시작). 변경 시 자동으로 컬럼을 다시 매핑합니다.
                        </div>
                    </div>

                    <!-- 엑셀 미리보기 + 컬럼 매핑 통합 -->
                    <div id="excelPreviewContainer" style="display: none;" class="mb-3">
                        <label class="form-label">
                            <i class="fas fa-table me-1"></i>엑셀 파일 미리보기 및 컬럼 매핑
                            <span class="badge bg-danger ms-2">평가 필수 항목은 반드시 매핑하세요</span>
                        </label>
                        <div class="card">
                            <div class="card-body" style="max-height: 600px; overflow: auto;">
                                <table class="table table-sm table-bordered" id="previewTable" style="font-size: 11px;">
                                    <thead id="previewTableHead" style="position: sticky; top: 0; background: white; z-index: 10;">
                                        <!-- 컬럼 매핑 드롭다운 행 -->
                                    </thead>
                                    <tbody id="previewTableBody"></tbody>
                                </table>
                            </div>
                        </div>
                        <div class="form-text mt-2">
                            <i class="fas fa-info-circle me-1"></i>
                            <strong>행 번호</strong>를 클릭하여 헤더 행 선택 | 각 컬럼 상단의 드롭다운에서 매핑할 항목 선택
                        </div>
                    </div>

                    <!-- 평가 필수 항목 체크리스트 -->
                    <div id="requiredChecklistContainer" style="display: none;" class="mb-3">
                        <div class="card border-warning">
                            <div class="card-header bg-warning bg-opacity-10">
                                <h6 class="mb-0">
                                    <i class="fas fa-clipboard-check me-2"></i>평가 필수 항목 매핑 현황
                                    <span class="badge bg-success ms-2" id="mappingProgress">0/0</span>
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="row row-cols-auto" id="requiredChecklistItems" style="display: flex; flex-wrap: wrap;">
                                    <!-- 동적으로 생성됨 -->
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 컬럼 매핑 데이터 (hidden) -->
                    <input type="hidden" id="column_mapping" name="column_mapping" value="{}">

                    {% if users|length > 1 %}
                    <div class="mb-3">
                        <label class="form-label">접근 권한 부여 (선택)</label>
                        <select class="form-select" id="access_users" name="access_users" multiple size="10">
                            {% for user in users %}
                            <option value="{{ user.user_id }}">
                                {% if is_admin %}{{ user.company_name or '(회사명 없음)' }} - {% endif %}{{ user.user_name }} ({{ user.user_email }})
                            </option>
                            {% endfor %}
                        </select>
                        <div class="form-text">
                            <i class="fas fa-info-circle me-1"></i>
                            Ctrl(Cmd) + 클릭으로 여러 사용자를 선택할 수 있습니다.
                            {% if is_admin %}
                            선택하지 않으면 업로드한 관리자만 접근 가능합니다.
                            {% else %}
                            업로드한 사용자는 자동으로 관리 권한이 부여됩니다.
                            {% endif %}
                        </div>
                    </div>
                    {% endif %}

                    <div class="d-grid gap-2">
                        <button type="submit" class="btn btn-gradient btn-lg">
                            <i class="fas fa-upload me-2"></i>업로드
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- 중요 안내 -->
        <div class="alert alert-warning mt-4">
            <h5 class="alert-heading">
                <i class="fas fa-exclamation-triangle me-2"></i>RCM 수정 관련 안내
            </h5>
            <hr>
            <p class="mb-2">
                <strong>한번 업로드된 RCM은 수정할 수 없습니다.</strong>
            </p>
            <p class="mb-2">
                업로드된 RCM은 현재 진행 중인 평가에서 사용되고 있을 수 있으며, 수정 시 평가 데이터의 일관성이 깨질 수 있습니다.
            </p>
            <p class="mb-0">
                <i class="fas fa-lightbulb me-1 text-warning"></i>
                <strong>RCM 내용을 수정해야 하는 경우:</strong>
            </p>
            <ol class="mb-0 mt-2">
                <li>RCM 목록에서 기존 RCM을 <strong>삭제</strong>합니다</li>
                <li>수정된 내용으로 <strong>새로운 RCM을 업로드</strong>합니다</li>
            </ol>
            <div class="mt-3 p-2 bg-light border-start border-info border-3">
                <p class="mb-1"><strong>📋 평가 진행 중 RCM 변경 정책:</strong></p>
                <ul class="mb-0 small">
                    <li><strong class="text-danger">운영평가 진행 중</strong>: RCM 삭제 불가 ⛔</li>
                    <li><strong class="text-warning">설계평가 진행 중</strong>: 경고 후 삭제 가능 ⚠️ (평가 데이터 삭제됨)</li>
                    <li><strong class="text-success">평가 없음</strong>: 자유롭게 삭제 가능 ✅</li>
                </ul>
            </div>
            <p class="mb-0 mt-2">
                <small class="text-muted">
                    <i class="fas fa-info-circle me-1"></i>
                    본인이 업로드한 RCM은 자동으로 삭제 권한이 부여됩니다.
                </small>
            </p>
        </div>

        <!-- 업로드 안내 -->
        <div class="card mt-4">
            <div class="card-header bg-info text-white">
                <i class="fas fa-question-circle me-2"></i>업로드 안내
            </div>
            <div class="card-body">
                <h5>Excel 파일 형식</h5>
                <ul>
                    <li>파일을 선택하면 <strong>미리보기</strong>가 자동으로 표시됩니다</li>
                    <li>미리보기에서 <strong>행 번호를 클릭</strong>하여 헤더 행을 선택할 수 있습니다</li>
                    <li>기본적으로 첫 번째 행(0행)을 컬럼명으로 사용합니다</li>
                    <li>각 행은 하나의 통제 항목을 나타냅니다</li>
                    <li>빈 행은 자동으로 제외됩니다</li>
                    <li>컬럼명은 영문/한글 모두 지원하며 자동으로 매핑됩니다</li>
                </ul>

                <h5 class="mt-3">카테고리 설명</h5>
                <ul>
                    <li><strong>ELC (Entity Level Controls)</strong>: 전사적 통제 - 조직 전체에 영향을 미치는 통제</li>
                    <li><strong>TLC (Transaction Level Controls)</strong>: 거래 수준 통제 - 개별 거래에 대한 통제</li>
                    <li><strong>ITGC (IT General Controls)</strong>: IT 일반 통제 - IT 시스템 및 인프라에 대한 통제</li>
                </ul>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // 카테고리별 평가 필수 컬럼 정의 (설계/운영평가에 필요한 항목)
        const REQUIRED_COLUMNS = {
            'ELC': ['control_code', 'control_name', 'control_description', 'key_control', 'control_frequency', 'control_type', 'control_nature', 'population', 'test_procedure'],
            'TLC': ['control_code', 'control_name', 'control_description', 'key_control', 'control_frequency', 'control_type', 'control_nature', 'population', 'test_procedure'],
            'ITGC': ['control_code', 'control_name', 'control_description', 'key_control', 'control_frequency', 'control_type', 'control_nature', 'test_procedure']
        };

        // 컬럼 한글 이름
        const COLUMN_LABELS = {
            'control_code': '통제코드',
            'control_name': '통제명',
            'control_description': '통제설명',
            'key_control': '핵심통제 여부',
            'control_frequency': '통제주기',
            'control_type': '통제성격 (예방/적발)',
            'control_nature': '통제방법 (자동/수동)',
            'system': '시스템',
            'population': '모집단',
            'test_procedure': '테스트 방법',
            'population_completeness_check': '모집단 완전성 확인',
            'population_count': '모집단 건수'
        };

        let previewData = null;
        let columnInfo = null;
        let headerRowIndex = 0;
        let selectedStdColumn = null; // 현재 선택된 표준 컬럼
        let selectedExcelColumn = null; // 현재 선택된 엑셀 컬럼

        // 파일 선택 시 미리보기 표시
        document.getElementById('rcm_file').addEventListener('change', async function(e) {
            const file = e.target.files[0];
            if (!file) {
                document.getElementById('excelPreviewContainer').style.display = 'none';
                document.getElementById('fileLoadingIndicator').style.display = 'none';
                return;
            }

            // 로딩 인디케이터 표시
            document.getElementById('fileLoadingIndicator').style.display = 'block';
            document.getElementById('loadingStatusText').textContent = '파일을 읽고 있습니다...';
            document.getElementById('excelPreviewContainer').style.display = 'none';
            document.getElementById('headerRowContainer').style.display = 'none';

            // 미리보기 요청
            const formData = new FormData();
            formData.append('file', file);

            try {
                // 상태 업데이트
                setTimeout(() => {
                    document.getElementById('loadingStatusText').textContent = '엑셀 데이터를 분석하고 있습니다...';
                }, 500);

                const response = await fetch('{{ url_for("link5.rcm_preview_excel") }}', {
                    method: 'POST',
                    body: formData
                });

                const result = await response.json();

                if (result.success) {
                    // 상태 업데이트
                    document.getElementById('loadingStatusText').textContent = '미리보기를 생성하고 있습니다...';

                    previewData = result.data;
                    columnInfo = result.columns;

                    displayPreview(result.data);

                    // 상태 업데이트
                    document.getElementById('loadingStatusText').textContent = '컬럼 매핑을 준비하고 있습니다...';

                    document.getElementById('headerRowContainer').style.display = 'block';
                    document.getElementById('excelPreviewContainer').style.display = 'block';

                    // 컬럼 매핑 헤더 생성
                    setTimeout(() => {
                        createColumnMappingHeader(0); // 기본값: 0행

                        // 완료 후 로딩 인디케이터 숨김
                        document.getElementById('loadingStatusText').textContent = '완료!';
                        setTimeout(() => {
                            document.getElementById('fileLoadingIndicator').style.display = 'none';
                        }, 500);
                    }, 100);
                } else {
                    document.getElementById('fileLoadingIndicator').style.display = 'none';
                    alert('미리보기 실패: ' + result.message);
                    document.getElementById('headerRowContainer').style.display = 'none';
                    document.getElementById('excelPreviewContainer').style.display = 'none';
                }
            } catch (error) {
                console.error('Error:', error);
                document.getElementById('fileLoadingIndicator').style.display = 'none';
                alert('미리보기 중 오류가 발생했습니다.');
                document.getElementById('excelPreviewContainer').style.display = 'none';
                document.getElementById('columnMappingContainer').style.display = 'none';
            }
        });

        // 미리보기 테이블 표시
        function displayPreview(data) {
            const tbody = document.getElementById('previewTableBody');
            tbody.innerHTML = '';

            data.forEach(row => {
                const tr = document.createElement('tr');

                // 행 번호 셀 추가
                const rowNumCell = document.createElement('td');
                rowNumCell.style.cssText = 'background-color: #f8f9fa; font-weight: bold; text-align: center; width: 50px; cursor: pointer;';
                rowNumCell.textContent = row.row_index;
                rowNumCell.title = '클릭하여 이 행을 헤더로 설정';

                // 행 번호 클릭 시 헤더 행으로 설정
                rowNumCell.addEventListener('click', function() {
                    headerRowIndex = row.row_index;
                    document.getElementById('header_row').value = row.row_index;
                    highlightHeaderRow(row.row_index);
                    createColumnMappingHeader(row.row_index);
                });

                tr.appendChild(rowNumCell);

                // 데이터 셀 추가
                row.cells.forEach((cell, colIndex) => {
                    const td = document.createElement('td');
                    td.textContent = cell;
                    td.style.cssText = 'white-space: nowrap; max-width: 200px; overflow: hidden; text-overflow: ellipsis;';
                    td.title = cell; // 전체 텍스트를 툴팁으로
                    td.dataset.columnIndex = colIndex;

                    tr.appendChild(td);
                });

                tbody.appendChild(tr);
            });

            // 기본 헤더 행 하이라이트
            highlightHeaderRow(0);
        }

        // 헤더 행 하이라이트
        function highlightHeaderRow(rowIndex) {
            const tbody = document.getElementById('previewTableBody');
            const rows = tbody.querySelectorAll('tr');

            rows.forEach((tr, idx) => {
                if (idx === rowIndex) {
                    tr.style.backgroundColor = '#d1ecf1';
                    tr.style.fontWeight = 'bold';
                } else {
                    tr.style.backgroundColor = '';
                    tr.style.fontWeight = '';
                }
            });
        }

        // 헤더 행 입력 필드 변경 시 하이라이트 업데이트
        document.getElementById('header_row').addEventListener('input', function(e) {
            const rowIndex = parseInt(e.target.value);
            if (!isNaN(rowIndex)) {
                headerRowIndex = rowIndex;
                highlightHeaderRow(rowIndex);
                createColumnMappingHeader(rowIndex);
            }
        });

        // 컬럼 하이라이트
        function highlightColumn(colIndex, highlight) {
            const tbody = document.getElementById('previewTableBody');
            const rows = tbody.querySelectorAll('tr');

            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                // +1은 행 번호 셀 때문
                if (cells[colIndex + 1]) {
                    if (highlight) {
                        cells[colIndex + 1].style.backgroundColor = '#fff3cd';
                    } else {
                        // 선택된 컬럼이면 파란색 유지, 아니면 원래대로
                        if (selectedExcelColumn === colIndex) {
                            cells[colIndex + 1].style.backgroundColor = '#cfe2ff';
                        } else if (row.querySelector('td:first-child').textContent == headerRowIndex) {
                            cells[colIndex + 1].style.backgroundColor = '#d1ecf1';
                        } else {
                            cells[colIndex + 1].style.backgroundColor = '';
                        }
                    }
                }
            });
        }

        // 엑셀 컬럼 선택
        function selectExcelColumn(colIndex) {
            if (!selectedStdColumn) {
                return;
            }

            // 이전 선택 해제
            if (selectedExcelColumn !== null) {
                highlightColumn(selectedExcelColumn, false);
            }

            // 새로운 선택
            selectedExcelColumn = colIndex;
            highlightColumn(colIndex, false); // false를 전달하여 선택된 색상 적용

            // 컬럼 전체를 파란색으로
            const tbody = document.getElementById('previewTableBody');
            const rows = tbody.querySelectorAll('tr');
            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                if (cells[colIndex + 1]) {
                    cells[colIndex + 1].style.backgroundColor = '#cfe2ff';
                }
            });

            // 드롭다운에 값 설정
            const select = document.getElementById(`mapping_${selectedStdColumn}`);
            if (select) {
                select.value = colIndex;
                // 드롭다운 하이라이트
                select.style.backgroundColor = '#d1ecf1';
                setTimeout(() => {
                    select.style.backgroundColor = '';
                }, 1000);
            }

            // 선택 해제
            selectedStdColumn = null;

            // 모든 매핑 드롭다운의 포커스 표시 제거
            document.querySelectorAll('[id^="mapping_"]').forEach(sel => {
                sel.parentElement.style.border = '';
            });
        }

        // 컬럼 매핑 헤더 생성 (테이블 상단에 드롭다운)
        function createColumnMappingHeader(rowIndex) {
            const category = document.getElementById('control_category').value;
            const requiredCols = REQUIRED_COLUMNS[category] || [];

            if (!previewData || !previewData[rowIndex]) {
                return;
            }

            const headerRow = previewData[rowIndex].cells;
            const thead = document.getElementById('previewTableHead');
            thead.innerHTML = '';

            // 매핑 드롭다운 행 생성
            const mappingRow = document.createElement('tr');
            mappingRow.style.backgroundColor = '#f8f9fa';

            // 첫 번째 셀 (행 번호 열)
            const emptyTh = document.createElement('th');
            emptyTh.style.cssText = 'width: 50px; text-align: center; font-weight: bold;';
            emptyTh.innerHTML = '<i class="fas fa-exchange-alt"></i>';
            emptyTh.title = '컬럼 매핑';
            mappingRow.appendChild(emptyTh);

            // 각 엑셀 컬럼마다 드롭다운 생성
            headerRow.forEach((cellValue, colIndex) => {
                const th = document.createElement('th');
                th.style.cssText = 'padding: 5px; min-width: 150px;';

                const select = document.createElement('select');
                select.className = 'form-select form-select-sm';
                select.id = `mapping_col_${colIndex}`;
                select.dataset.columnIndex = colIndex;
                select.style.fontSize = '11px';

                // 기본 옵션
                const defaultOption = document.createElement('option');
                defaultOption.value = '';
                defaultOption.textContent = '- 선택 안함 -';
                select.appendChild(defaultOption);

                // 모든 표준 컬럼 옵션 (논리적 순서로)
                const allStdColumns = ['control_code', 'control_name', 'control_description',
                                       'key_control', 'control_frequency', 'control_type', 'control_nature',
                                       'system', 'population', 'test_procedure',
                                       'population_completeness_check', 'population_count'];

                allStdColumns.forEach(stdCol => {
                    const option = document.createElement('option');
                    option.value = stdCol;
                    const label = COLUMN_LABELS[stdCol] || stdCol;
                    const isRequired = requiredCols.includes(stdCol);
                    const baseText = isRequired ? `${label} *` : label;
                    option.textContent = baseText;
                    option.dataset.baseText = baseText; // 원본 텍스트 저장
                    if (isRequired) {
                        option.style.fontWeight = 'bold';
                        option.style.color = '#dc3545';
                    }
                    select.appendChild(option);
                });

                // 자동 매핑 시도 (중복 방지 포함)
                select.dataset.autoMatched = 'false';  // 초기화

                // 드롭다운 변경 시 중복 검증 및 컬럼 하이라이트
                select.addEventListener('change', function() {
                    handleMappingChange(this);
                    updateColumnHighlights();
                });

                th.appendChild(select);
                mappingRow.appendChild(th);
            });

            thead.appendChild(mappingRow);

            // 평가 필수 항목 체크리스트 생성
            createRequiredChecklist(requiredCols);

            // 자동 매핑 실행 (중복 방지 로직 포함)
            performAutoMapping(headerRow);
        }

        // 평가 필수 항목 체크리스트 생성
        function createRequiredChecklist(requiredCols) {
            const container = document.getElementById('requiredChecklistItems');
            container.innerHTML = '';

            requiredCols.forEach(stdCol => {
                const colDiv = document.createElement('div');
                colDiv.className = 'col mb-2';
                colDiv.style.minWidth = '180px';

                const checkItem = document.createElement('div');
                checkItem.className = 'form-check';
                checkItem.id = `check_${stdCol}`;
                checkItem.style.cursor = 'pointer';
                checkItem.title = '클릭하여 매핑된 컬럼 확인';

                const checkbox = document.createElement('i');
                checkbox.className = 'fas fa-square me-2';
                checkbox.style.color = '#dc3545';
                checkbox.id = `icon_${stdCol}`;

                const label = document.createElement('span');
                label.textContent = COLUMN_LABELS[stdCol] || stdCol;
                label.style.color = '#6c757d';
                label.id = `label_${stdCol}`;

                // 클릭 이벤트 추가
                checkItem.addEventListener('click', function() {
                    highlightMappedColumn(stdCol);
                });

                checkItem.appendChild(checkbox);
                checkItem.appendChild(label);
                colDiv.appendChild(checkItem);
                container.appendChild(colDiv);
            });

            document.getElementById('requiredChecklistContainer').style.display = 'block';
            updateRequiredChecklist();
        }

        // 매핑된 컬럼 하이라이트 (체크리스트 클릭 시)
        function highlightMappedColumn(stdCol) {
            // 해당 표준 컬럼이 매핑된 엑셀 컬럼 찾기
            let mappedColIndex = null;
            document.querySelectorAll('[id^="mapping_col_"]').forEach(select => {
                if (select.value === stdCol) {
                    mappedColIndex = parseInt(select.dataset.columnIndex);
                }
            });

            if (mappedColIndex === null) {
                alert(`"${COLUMN_LABELS[stdCol]}"은(는) 아직 매핑되지 않았습니다.`);
                return;
            }

            // 모든 컬럼 하이라이트 제거
            const tbody = document.getElementById('previewTableBody');
            const thead = document.getElementById('previewTableHead');
            const rows = tbody.querySelectorAll('tr');

            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                cells.forEach((cell, idx) => {
                    if (idx === 0) return; // 행 번호 셀 제외
                    const colIdx = idx - 1;
                    if (row.querySelector('td:first-child').textContent == headerRowIndex) {
                        cell.style.backgroundColor = '#d1ecf1'; // 헤더 행
                    } else {
                        cell.style.backgroundColor = '';
                    }
                    // 기존 하이라이트 제거
                    cell.style.border = '';
                });
            });

            // 매핑된 컬럼만 강조 (밝은 노란색)
            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                if (cells[mappedColIndex + 1]) {
                    cells[mappedColIndex + 1].style.backgroundColor = '#fff3cd';
                    cells[mappedColIndex + 1].style.border = '3px solid #ffc107';
                    cells[mappedColIndex + 1].style.transition = 'all 0.3s ease';
                }
            });

            // 해당 드롭다운도 강조
            const select = document.getElementById(`mapping_col_${mappedColIndex}`);
            if (select) {
                select.style.backgroundColor = '#fff3cd';
                select.style.border = '2px solid #ffc107';
                select.style.transition = 'all 0.3s ease';

                // 매핑된 컬럼이 화면에 보이도록 수평 스크롤
                const previewContainer = document.querySelector('#excelPreviewContainer .card-body');
                if (previewContainer && rows.length > 0) {
                    const firstCell = rows[0].querySelectorAll('td')[mappedColIndex + 1];
                    if (firstCell) {
                        const containerRect = previewContainer.getBoundingClientRect();
                        const cellRect = firstCell.getBoundingClientRect();

                        // 셀이 화면에 보이지 않으면 스크롤
                        if (cellRect.left < containerRect.left || cellRect.right > containerRect.right) {
                            const scrollLeft = firstCell.offsetLeft - (previewContainer.clientWidth / 2) + (firstCell.offsetWidth / 2);
                            previewContainer.scrollTo({
                                left: scrollLeft,
                                behavior: 'smooth'
                            });
                        }
                    }
                }

                // 10초 후 강조 제거 (기존 3초에서 증가)
                setTimeout(() => {
                    select.style.backgroundColor = '';
                    select.style.border = '';

                    // 컬럼 강조도 제거하고 원래 상태로
                    rows.forEach(row => {
                        const cells = row.querySelectorAll('td');
                        if (cells[mappedColIndex + 1]) {
                            cells[mappedColIndex + 1].style.border = '';
                            if (row.querySelector('td:first-child').textContent == headerRowIndex) {
                                cells[mappedColIndex + 1].style.backgroundColor = '#d1ecf1';
                            } else {
                                cells[mappedColIndex + 1].style.backgroundColor = '';
                            }
                        }
                    });
                }, 10000); // 3초 → 10초로 변경
            }
        }

        // 자동 매핑 실행 (모든 항목 중복 방지)
        function performAutoMapping(headerRow) {
            console.log('performAutoMapping 시작, headerRow:', headerRow);
            const mappedStdCols = {}; // 이미 매핑된 모든 항목 추적

            // 각 컬럼에 대해 자동 매핑 시도
            headerRow.forEach((cellValue, colIndex) => {
                const select = document.getElementById(`mapping_col_${colIndex}`);
                if (!select) {
                    console.log(`select 요소를 찾을 수 없음: mapping_col_${colIndex}`);
                    return;
                }

                const matchedStdCol = autoMatchColumnReverse(cellValue);
                console.log(`컬럼 ${colIndex} (${cellValue}) -> 매칭 결과: ${matchedStdCol}`);

                if (matchedStdCol) {
                    // 모든 항목에 대해 중복 확인
                    // 이미 매핑되지 않은 경우만 매핑
                    if (!mappedStdCols[matchedStdCol]) {
                        select.value = matchedStdCol;
                        mappedStdCols[matchedStdCol] = colIndex;
                        console.log(`자동 매핑 완료: 컬럼 ${colIndex} -> ${matchedStdCol}`);
                    } else {
                        console.log(`중복으로 인해 매핑 스킵: ${matchedStdCol} (이미 컬럼 ${mappedStdCols[matchedStdCol]}에 매핑됨)`);
                    }
                }
            });

            console.log('자동 매핑 결과:', mappedStdCols);
            // 자동 매핑 후 드롭다운 옵션 및 체크리스트 업데이트
            updateAllDropdownOptions();
            updateRequiredChecklist();
        }

        // 드롭다운 변경 시 중복 검증 처리 (자동 해제 방식)
        function handleMappingChange(selectElement) {
            const newValue = selectElement.value;
            const currentColIndex = selectElement.dataset.columnIndex;

            if (!newValue) {
                // 선택 해제한 경우 - 모든 드롭다운 옵션 업데이트
                updateAllDropdownOptions();
                updateRequiredChecklist();
                return;
            }

            // 모든 항목에 대해 중복 검증
            // 다른 드롭다운에서 같은 항목이 선택되어 있는지 확인
            let duplicateFound = false;
            let duplicateColIndex = -1;
            let duplicateSelect = null;

            document.querySelectorAll('[id^="mapping_col_"]').forEach(otherSelect => {
                const otherColIndex = otherSelect.dataset.columnIndex;

                // 자기 자신은 제외
                if (otherColIndex !== currentColIndex && otherSelect.value === newValue) {
                    duplicateFound = true;
                    duplicateColIndex = otherColIndex;
                    duplicateSelect = otherSelect;
                }
            });

            if (duplicateFound) {
                // 기존 매핑을 자동으로 해제하고 알림 메시지 표시
                const headerRow = previewData[headerRowIndex].cells;
                const oldColumnName = headerRow[duplicateColIndex] || `컬럼 ${duplicateColIndex}`;
                const newColumnName = headerRow[currentColIndex] || `컬럼 ${currentColIndex}`;

                alert(`"${COLUMN_LABELS[newValue]}" 매핑이 변경되었습니다.\n\n이전: ${oldColumnName}\n현재: ${newColumnName}`);

                // 기존 매핑 해제
                duplicateSelect.value = '';
            }

            // 모든 드롭다운 옵션 및 체크리스트 업데이트
            updateAllDropdownOptions();
            updateRequiredChecklist();
        }

        // 모든 드롭다운의 옵션 상태 업데이트 (자동 해제 방식에서는 비활성화 불필요)
        function updateAllDropdownOptions() {
            // 현재 매핑된 모든 항목 수집 (컬럼 인덱스별로)
            const mappedStdCols = {};
            document.querySelectorAll('[id^="mapping_col_"]').forEach(select => {
                const value = select.value;
                const colIndex = select.dataset.columnIndex;
                if (value) {
                    mappedStdCols[value] = colIndex;
                }
            });

            // 각 드롭다운의 옵션에 매핑 상태 표시 (정보 제공용)
            document.querySelectorAll('[id^="mapping_col_"]').forEach(select => {
                const currentColIndex = select.dataset.columnIndex;
                const currentValue = select.value;

                // 모든 옵션을 순회하며 매핑 상태 표시
                Array.from(select.options).forEach(option => {
                    const optionValue = option.value;

                    if (!optionValue) {
                        return;
                    }

                    const baseText = option.dataset.baseText || option.textContent;

                    // 이미 다른 컬럼에 매핑되어 있는지 표시 (선택은 가능)
                    if (mappedStdCols[optionValue] && mappedStdCols[optionValue] !== currentColIndex) {
                        const headerRow = previewData[headerRowIndex].cells;
                        const mappedColName = headerRow[mappedStdCols[optionValue]] || `컬럼 ${mappedStdCols[optionValue]}`;
                        option.style.color = '#6c757d';
                        option.textContent = `${baseText} (매핑됨: ${mappedColName})`;
                    } else {
                        option.style.color = '';
                        option.textContent = baseText;
                    }
                });
            });
        }

        // 역방향 자동 매칭 (엑셀 컬럼명 -> 표준 컬럼) - 개선된 버전
        function autoMatchColumnReverse(excelColName) {
            if (!excelColName) return null;

            const normalized = excelColName.toString().toLowerCase().trim()
                .replace(/\s+/g, '')  // 공백 제거
                .replace(/[^\w가-힣]/g, '');  // 특수문자 제거

            // 우선순위 1: 정확한 매칭
            for (const [stdCol, label] of Object.entries(COLUMN_LABELS)) {
                const normalizedLabel = label.toLowerCase().replace(/\s+/g, '').replace(/[^\w가-힣]/g, '');
                if (normalized === normalizedLabel || normalized === stdCol.toLowerCase()) {
                    return stdCol;
                }
            }

            // 우선순위 2: 포함 관계 (키워드 매칭)
            const keywords = {
                'control_code': ['통제코드', '코드', 'code', 'controlcode'],
                'control_name': ['통제명', '통제이름', '통제name', 'controlname', 'name'],
                'control_description': ['통제설명', '설명', '통제내용', 'description', 'desc'],
                'key_control': ['핵심통제', '핵심', 'key', 'keycontrol', '중요통제'],
                'control_frequency': ['통제주기', '주기', '빈도', 'frequency', 'freq'],
                'control_type': ['통제성격', '통제유형', '성격', '유형', 'type', '예방', '적발'],
                'control_nature': ['통제방법', '통제속성', '통제구분', '방법', '속성', '구분', 'nature', '자동', '수동'],
                'system': ['시스템', 'system', 'sys', '어플리케이션', 'app'],
                'population': ['모집단', '대상', 'population', 'pop'],
                'test_procedure': ['테스트', '검증', '절차', 'test', 'procedure', 'proc'],
                'population_completeness_check': ['완전성', '모집단완전성', 'completeness'],
                'population_count': ['모집단건수', '건수', 'count', '수량']
            };

            for (const [stdCol, keywordList] of Object.entries(keywords)) {
                for (const keyword of keywordList) {
                    const normalizedKeyword = keyword.toLowerCase().replace(/\s+/g, '');
                    if (normalized.includes(normalizedKeyword) || normalizedKeyword.includes(normalized)) {
                        return stdCol;
                    }
                }
            }

            return null;
        }

        // 컬럼 하이라이트 업데이트
        function updateColumnHighlights() {
            const tbody = document.getElementById('previewTableBody');
            const rows = tbody.querySelectorAll('tr');
            const mappedColumns = new Set();

            // 매핑된 컬럼 찾기
            document.querySelectorAll('[id^="mapping_col_"]').forEach(select => {
                if (select.value) {
                    const colIndex = parseInt(select.dataset.columnIndex);
                    mappedColumns.add(colIndex);
                }
            });

            // 컬럼 색상 적용
            rows.forEach((row, rowIdx) => {
                const cells = row.querySelectorAll('td');
                cells.forEach((cell, cellIdx) => {
                    if (cellIdx === 0) return; // 행 번호 셀 제외

                    const colIndex = cellIdx - 1;
                    if (mappedColumns.has(colIndex)) {
                        if (rowIdx === headerRowIndex) {
                            cell.style.backgroundColor = '#d1ecf1';
                        } else {
                            cell.style.backgroundColor = '#e7f3ff';
                        }
                    } else {
                        if (rowIdx === headerRowIndex) {
                            cell.style.backgroundColor = '#d1ecf1';
                        } else {
                            cell.style.backgroundColor = '';
                        }
                    }
                });
            });

            // 평가 필수 항목 체크리스트 업데이트
            updateRequiredChecklist();
        }

        // 평가 필수 항목 체크리스트 업데이트
        function updateRequiredChecklist() {
            const category = document.getElementById('control_category').value;
            const requiredCols = REQUIRED_COLUMNS[category] || [];

            // 현재 매핑된 표준 컬럼 수집
            const mappedStdCols = new Set();
            document.querySelectorAll('[id^="mapping_col_"]').forEach(select => {
                if (select.value) {
                    mappedStdCols.add(select.value);
                }
            });

            let completedCount = 0;

            // 각 필수 항목 체크 상태 업데이트
            requiredCols.forEach(stdCol => {
                const icon = document.getElementById(`icon_${stdCol}`);
                const label = document.getElementById(`label_${stdCol}`);

                if (icon && label) {
                    if (mappedStdCols.has(stdCol)) {
                        // 매핑됨
                        icon.className = 'fas fa-check-square me-2';
                        icon.style.color = '#28a745';
                        label.style.color = '#28a745';
                        label.style.fontWeight = 'bold';
                        completedCount++;
                    } else {
                        // 미매핑
                        icon.className = 'fas fa-square me-2';
                        icon.style.color = '#dc3545';
                        label.style.color = '#6c757d';
                        label.style.fontWeight = 'normal';
                    }
                }
            });

            // 진행률 업데이트
            const progressBadge = document.getElementById('mappingProgress');
            if (progressBadge) {
                progressBadge.textContent = `${completedCount}/${requiredCols.length}`;
                if (completedCount === requiredCols.length) {
                    progressBadge.className = 'badge bg-success ms-2';
                } else {
                    progressBadge.className = 'badge bg-warning ms-2';
                }
            }
        }

        // 컬럼 자동 매칭 (간단한 문자열 매칭)
        function autoMatchColumn(stdCol, headerRow) {
            const label = COLUMN_LABELS[stdCol];
            const searchTerms = [label, stdCol];

            for (let i = 0; i < headerRow.length; i++) {
                const cellValue = (headerRow[i] || '').toString().toLowerCase().trim();
                for (const term of searchTerms) {
                    if (cellValue.includes(term.toLowerCase()) || term.toLowerCase().includes(cellValue)) {
                        return i;
                    }
                }
            }
            return -1;
        }

        // 카테고리 변경 시 컬럼 매핑 재생성 (기존 매핑 유지)
        document.getElementById('control_category').addEventListener('change', function() {
            if (previewData) {
                // 현재 매핑 상태 저장
                const currentMappings = {};
                document.querySelectorAll('[id^="mapping_col_"]').forEach(select => {
                    const colIndex = parseInt(select.dataset.columnIndex);
                    const stdCol = select.value;
                    if (stdCol) {
                        currentMappings[colIndex] = stdCol;
                    }
                });

                // 컬럼 매핑 헤더 재생성
                createColumnMappingHeader(headerRowIndex);

                // 저장된 매핑 복원
                setTimeout(() => {
                    Object.entries(currentMappings).forEach(([colIndex, stdCol]) => {
                        const select = document.getElementById(`mapping_col_${colIndex}`);
                        if (select) {
                            select.value = stdCol;
                        }
                    });
                    updateColumnHighlights();
                }, 100);
            }
        });

        // 폼 제출
        document.getElementById('rcmUploadForm').addEventListener('submit', async function(e) {
            e.preventDefault();

            // 컬럼 매핑 검증 (새로운 테이블 헤더 드롭다운에서)
            const category = document.getElementById('control_category').value;
            const requiredCols = REQUIRED_COLUMNS[category] || [];
            const columnMapping = {};
            const missingColumns = [];

            // 컬럼 매핑 수집 (각 엑셀 컬럼의 드롭다운에서)
            document.querySelectorAll('[id^="mapping_col_"]').forEach(select => {
                const colIndex = parseInt(select.dataset.columnIndex);
                const stdCol = select.value;

                if (stdCol) {
                    columnMapping[stdCol] = colIndex;
                }
            });

            // 평가 필수 컬럼 검증
            requiredCols.forEach(col => {
                if (!columnMapping[col] && columnMapping[col] !== 0) {
                    missingColumns.push(COLUMN_LABELS[col] || col);
                }
            });

            if (missingColumns.length > 0) {
                alert(`다음 평가 필수 항목을 매핑해주세요:\n\n${missingColumns.join('\n')}`);
                return;
            }

            const formData = new FormData(this);

            // 컬럼 매핑 정보 추가
            formData.set('column_mapping', JSON.stringify(columnMapping));

            // 선택된 사용자들을 배열로 변환
            const accessUsersSelect = document.getElementById('access_users');
            if (accessUsersSelect) {
                const accessUsers = Array.from(accessUsersSelect.selectedOptions)
                                         .map(option => option.value);

                // 기존 access_users 제거 후 JSON 형태로 추가
                formData.delete('access_users');
                accessUsers.forEach(userId => {
                    formData.append('access_users', userId);
                });
            }

            try {
                const response = await fetch('{{ url_for("link5.rcm_process_upload") }}', {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();

                if (data.success) {
                    alert('RCM이 성공적으로 업로드되었습니다.');
                    window.location.href = '{{ url_for("link5.user_rcm") }}';
                } else {
                    alert('업로드 실패: ' + data.message);
                }
            } catch (error) {
                console.error('Error:', error);
                alert('업로드 중 오류가 발생했습니다.');
            }
        });
    </script>
</body>
</html>
