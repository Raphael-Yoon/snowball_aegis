<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - RCM 상세보기 - {{ rcm_info.rcm_name }}</title>
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
            width: 100%; /* 부모 요소에 맞춤 */
        }
        #rcmTable th, #rcmTable td {
            word-wrap: break-word;
            overflow-wrap: break-word;
            vertical-align: top;
        }
        .text-truncate-custom {
            /* 이 클래스는 더 이상 사용되지 않으므로 스타일을 제거하거나 비워둡니다. */
        }
        /* Chrome, Safari, Edge, Opera - 숫자 입력 필드 화살표 제거 */
        input[type=number]:not(.population-spinner)::-webkit-inner-spin-button,
        input[type=number]:not(.population-spinner)::-webkit-outer-spin-button {
            -webkit-appearance: none;
            margin: 0;
        }
        /* Firefox - 숫자 입력 필드 화살표 제거 */
        input[type=number]:not(.population-spinner) {
            -moz-appearance: textfield;
        }

        /* 모집단 항목 수 입력 필드에만 스피너 표시 */
        #population-attr-count::-webkit-inner-spin-button,
        #population-attr-count::-webkit-outer-spin-button {
            -webkit-appearance: inner-spin-button !important;
            display: inline-block !important;
            opacity: 1 !important;
        }
        #population-attr-count {
            -moz-appearance: number-input !important;
        }

        /* 인라인 편집 스타일 */
        .editable-cell:hover {
            border-color: #0d6efd !important;
            background-color: #f8f9fa;
            cursor: text;
        }

        .editable-cell:focus {
            outline: none;
            border-color: #0d6efd !important;
            background-color: #fff;
            box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.25);
        }

        /* 컬럼 고정 스타일 */
        #rcmTable th:nth-child(1) {
            position: sticky;
            left: 0;
        }

        #rcmTable td:nth-child(1) {
            position: sticky;
            left: 0;
            z-index: 3;
        }

        #rcmTable th:nth-child(2) {
            position: sticky;
            left: 80px; /* 통제코드 컬럼 너비 */
        }

        #rcmTable td:nth-child(2) {
            position: sticky;
            left: 80px;
            z-index: 3;
        }

        /* 통제활동 설명 컬럼도 고정 */
        #rcmTable th:nth-child(3) {
            position: sticky;
            left: 230px; /* 통제코드(80px) + 통제명(150px) */
        }

        #rcmTable td:nth-child(3) {
            position: sticky;
            left: 230px;
            z-index: 3;
        }

        /* 고정된 헤더의 배경색을 지정하여 스크롤 시 내용이 비치지 않도록 함 */
        #rcmTable thead th {
            background-color: #f8f9fa; /* thead 배경색 */
            position: sticky;
            top: 0;
            z-index: 10;
        }

        /* 고정된 헤더와 고정된 컬럼이 만나는 지점 */
        #rcmTable thead th:nth-child(1),
        #rcmTable thead th:nth-child(2),
        #rcmTable thead th:nth-child(3),
        #rcmTable thead th:nth-child(9) {
            z-index: 11;
        }

        /* 고정된 바디 셀의 배경색을 지정 (줄무늬 테이블 고려) */
        #rcmTable tbody tr td:nth-child(1),
        #rcmTable tbody tr td:nth-child(2),
        #rcmTable tbody tr td:nth-child(3),
        #rcmTable tbody tr td:nth-child(9) {
            background-color: #fff !important;
        }

        #rcmTable tbody tr:nth-of-type(odd) td:nth-child(1),
        #rcmTable tbody tr:nth-of-type(odd) td:nth-child(2),
        #rcmTable tbody tr:nth-of-type(odd) td:nth-child(3),
        #rcmTable tbody tr:nth-of-type(odd) td:nth-child(9) {
            background-color: #f9f9f9 !important;
        }

        /* Attribute 설정 컬럼을 오른쪽에 고정 */
        #rcmTable th:nth-child(9),
        #rcmTable td:nth-child(9) {
            position: sticky;
            right: 0;
            box-shadow: -2px 0 5px rgba(0,0,0,0.1);
        }

        /* Attribute 설정 바디 셀의 z-index */
        #rcmTable tbody tr td:nth-child(9) {
            z-index: 3;
        }

        .editable-cell.modified {
            background-color: #fff3cd !important;
            border-color: #ffc107 !important;
        }

        /* 모달 footer 버튼 높이 및 너비 통일 */
        .modal-footer .btn {
            height: 38px !important;
            min-height: 38px !important;
            max-height: 38px !important;
            width: auto !important;
            min-width: 80px !important;
            padding: 0.375rem 1rem !important;
            line-height: 1.5 !important;
            display: inline-flex !important;
            align-items: center !important;
            justify-content: center !important;
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
                        <a href="/user/rcm" class="btn btn-secondary">
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
                                <table class="table table-borderless mb-0">
                                    <tr>
                                        <th width="20%">RCM명:</th>
                                        <td><strong>{{ rcm_info.rcm_name }}</strong></td>
                                    </tr>
                                    <tr>
                                        <th>회사명:</th>
                                        <td>{{ rcm_info.company_name }}</td>
                                    </tr>
                                </table>
                            </div>
                            <div class="col-md-6">
                                <table class="table table-borderless mb-0">
                                    <tr>
                                        <th width="20%">설명:</th>
                                        <td>{{ rcm_info.description or '없음' }}</td>
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
                            <button class="btn btn-sm btn-outline-info me-2" onclick="autoCalculateSampleSizes()">
                                <i class="fas fa-calculator me-1"></i>표본수 자동계산
                            </button>
                            <button class="btn btn-sm btn-outline-secondary me-2" onclick="exportToExcel()">
                                <i class="fas fa-file-excel me-1"></i>Excel 다운로드
                            </button>
                            {% if rcm_info.control_category == 'ITGC' %}
                            <a href="/rcm/{{ rcm_info.rcm_id }}/mapping" class="btn btn-sm btn-outline-primary">
                                <i class="fas fa-link me-1"></i>기준통제 매핑
                            </a>
                            {% endif %}
                        </div>
                    </div>
                    <div class="card-body">
                        {% if rcm_details %}
                        <div class="table-responsive" style="max-height: 600px; overflow: auto;">
                            <table class="table table-striped table-hover" id="rcmTable" style="min-width: 1500px;">
                                <thead>
                                    <tr>
                                        <th style="min-width: 80px;">통제코드</th>
                                        <th style="min-width: 150px;">통제명</th>
                                        <th style="min-width: 300px; max-width: 400px;">통제활동 설명</th>
                                        <th style="min-width: 100px;">통제주기</th>
                                        <th style="min-width: 100px;">통제구분</th>
                                        <th style="min-width: 90px;">핵심통제</th>
                                        <th style="min-width: 80px;">기준통제</th>
                                        <th style="min-width: 300px; max-width: 400px;">테스트절차</th>
                                        <th style="min-width: 80px;">표본수</th>
                                        <th style="min-width: 120px;">Attribute 설정</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for detail in rcm_details %}
                                    <tr>
                                        <td><code>{{ detail.control_code }}</code></td>
                                        <td>
                                            <span class="text-truncate-custom">
                                                <strong>{{ detail.control_name }}</strong>
                                            </span>
                                        </td>
                                        <td>
                                            {% if detail.control_description %}
                                            <div class="text-truncate" style="max-width: 350px; cursor: pointer;"
                                                 onclick="showControlDescriptionModal('{{ detail.control_code }}', '{{ detail.control_name }}', `{{ detail.control_description|replace('`', '\\`')|replace('\n', '\\n') }}`)">
                                                {{ detail.control_description }}
                                            </div>
                                            {% else %}
                                            <span class="text-muted">-</span>
                                            {% endif %}
                                        </td>
                                        <td>
                                            <span class="text-truncate-custom">
                                                {{ detail.control_frequency_name or detail.control_frequency or '-' }}
                                            </span>
                                        </td>
                                        <td>
                                            <span class="text-truncate-custom">
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
                                        <td class="text-center">
                                            {% if detail.mapped_std_control_id %}
                                                <span class="badge bg-success"
                                                      style="cursor: pointer;"
                                                      title="클릭하여 기준통제 변경"
                                                      data-detail-id="{{ detail.detail_id }}"
                                                      data-control-code="{{ detail.control_code }}"
                                                      data-mapped-id="{{ detail.mapped_std_control_id }}"
                                                      onclick="openStdControlModal(this.dataset.detailId, this.dataset.controlCode, this.dataset.mappedId)">
                                                    <i class="fas fa-check-circle"></i> 매핑
                                                </span>
                                            {% else %}
                                                <span class="badge bg-secondary"
                                                      style="cursor: pointer;"
                                                      title="클릭하여 기준통제 매핑"
                                                      data-detail-id="{{ detail.detail_id }}"
                                                      data-control-code="{{ detail.control_code }}"
                                                      onclick="openStdControlModal(this.dataset.detailId, this.dataset.controlCode, null)">
                                                    <i class="fas fa-times-circle"></i> 미매핑
                                                </span>
                                            {% endif %}
                                        </td>
                                        <td>
                                            {% if detail.test_procedure %}
                                            <div class="text-truncate" style="max-width: 350px; cursor: pointer;"
                                                 onclick="showTestProcedureModal('{{ detail.control_code }}', '{{ detail.control_name }}', `{{ detail.test_procedure|replace('`', '\\`')|replace('\n', '\\n') }}`)">
                                                {{ detail.test_procedure }}
                                            </div>
                                            {% else %}
                                            <span class="text-muted">-</span>
                                            {% endif %}
                                        </td>
                                        <td class="text-center">
                                            <input type="text"
                                                   class="form-control form-control-sm text-center sample-size-input"
                                                   data-detail-id="{{ detail.detail_id if detail.detail_id is not none else '' }}"
                                                   data-field="recommended_sample_size"
                                                   data-control-code="{{ detail.control_code }}"
                                                   data-control-frequency="{{ detail.control_frequency_code or '' }}"
                                                   data-original-value="{{ detail.recommended_sample_size if detail.recommended_sample_size is not none else '' }}"
                                                   value="{{ detail.recommended_sample_size if detail.recommended_sample_size is not none else '' }}"
                                                   maxlength="3"
                                                   title="권장 표본수 (0: 모집단 업로드 모드)"
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
                            <p class="text-muted">관리자에게 문의하여 RCM 데이터를 확인하세요.</p>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 통제활동 설명 모달 -->
    <div class="modal fade" id="controlDescriptionModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-info-circle me-2"></i>통제활동 설명
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <strong>통제코드:</strong> <code id="desc-modal-control-code"></code><br>
                        <strong>통제명:</strong> <span id="desc-modal-control-name"></span>
                    </div>
                    <hr>
                    <div class="alert alert-light border">
                        <pre id="desc-modal-description" style="white-space: pre-wrap; word-wrap: break-word; margin: 0;"></pre>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i>닫기
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- 테스트 절차 모달 -->
    <div class="modal fade" id="testProcedureModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-clipboard-list me-2"></i>테스트 절차
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <strong>통제코드:</strong> <code id="test-modal-control-code"></code><br>
                        <strong>통제명:</strong> <span id="test-modal-control-name"></span>
                    </div>
                    <hr>
                    <div class="alert alert-light border">
                        <pre id="test-modal-procedure" style="white-space: pre-wrap; word-wrap: break-word; margin: 0;"></pre>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i>닫기
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- 기준통제 선택 모달 -->
    <div class="modal fade" id="stdControlModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-link me-2"></i>기준통제 매핑
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <strong>통제코드:</strong> <code id="std-modal-control-code"></code>
                    </div>
                    <hr>
                    <div class="alert alert-info">
                        <i class="fas fa-info-circle me-2"></i>
                        매핑할 기준통제를 선택하세요. 선택한 기준통제의 Attribute 템플릿이 자동으로 적용됩니다.
                    </div>
                    <div class="mb-3">
                        <input type="text" class="form-control" id="std-control-search" placeholder="기준통제 코드 또는 이름으로 검색...">
                    </div>
                    <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                        <table class="table table-hover table-sm">
                            <thead class="table-light sticky-top">
                                <tr>
                                    <th width="15%">카테고리</th>
                                    <th width="20%">통제코드</th>
                                    <th width="65%">통제명</th>
                                </tr>
                            </thead>
                            <tbody id="std-control-list">
                                <tr>
                                    <td colspan="3" class="text-center">
                                        <div class="spinner-border spinner-border-sm" role="status">
                                            <span class="visually-hidden">로딩중...</span>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i>취소
                    </button>
                    <button type="button" class="btn btn-danger" id="btn-unmap-std-control" style="display: none;">
                        <i class="fas fa-unlink me-1"></i>매핑 해제
                    </button>
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
                        증빙 항목으로 사용할 attribute 필드를 설정하세요. (예: 완료예정일, 완료여부, 승인자 등)
                    </div>
                    <div class="mb-3">
                        <label for="population-attr-count" class="form-label">
                            <strong>모집단 항목 수</strong>
                            <small class="text-muted">(attribute0부터 시작, 나머지는 증빙 항목)</small>
                        </label>
                        <input type="number"
                               class="form-control form-control-sm population-spinner"
                               id="population-attr-count"
                               min="0"
                               max="10"
                               value="2"
                               style="width: 100px;"
                               placeholder="0-10"
                               onchange="updateAttributeStyles()"
                               oninput="validatePopCount()">
                        <small class="text-muted">
                            0=모집단 없음(자동통제), 2=attribute0~1은 모집단, attribute2~9는 증빙
                        </small>
                    </div>
                    <table class="table table-sm table-bordered">
                        <thead>
                            <tr>
                                <th width="20%">Attribute</th>
                                <th width="10%">구분</th>
                                <th width="70%">필드명</th>
                            </tr>
                        </thead>
                        <tbody id="attribute-table-body">
                            {% for i in range(10) %}
                            <tr class="attribute-row" data-index="{{ i }}">
                                <td><strong>attribute{{ i }}</strong></td>
                                <td class="text-center">
                                    <span class="badge attribute-type-badge" data-index="{{ i }}"></span>
                                </td>
                                <td>
                                    <input type="text"
                                           class="form-control form-control-sm attribute-input"
                                           id="attr-input-{{ i }}"
                                           data-index="{{ i }}"
                                           placeholder="예: 계정ID, 완료일자, 승인자 등"
                                           maxlength="100">
                                </td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i>취소
                    </button>
                    <button type="button" class="btn btn-sm btn-primary" onclick="saveAttributes()">
                        <i class="fas fa-save me-1"></i>저장
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
    <script>
        // 기준통제 모달 관련 변수
        let stdControlModalInstance = null;
        let currentMappingRcmDetailId = null;
        let currentMappingControlCode = null;
        let allStdControls = [];

        // 통제주기별 기본 표본수 계산
        function getDefaultSampleSize(frequencyCode) {
            if (!frequencyCode) return 1;

            // 대소문자 구분 없이 처리
            const code = frequencyCode.toUpperCase();

            const frequencyMapping = {
                // 한글 코드
                'A': 1,  // 연
                'S': 1,  // 반기
                'Q': 2,  // 분기
                'M': 2,  // 월
                'W': 5,  // 주
                'D': 20, // 일
                'O': 1,  // 기타
                'N': 1,  // 필요시

                // 영문 전체 이름
                'ANNUALLY': 1,
                'SEMI-ANNUALLY': 1,
                'QUARTERLY': 2,
                'MONTHLY': 2,
                'WEEKLY': 5,
                'DAILY': 20,
                'MULTI-DAY': 25,  // 일 초과
                'AD-HOC': 1,
                'OTHER': 1
            };

            return frequencyMapping[code] || 1;
        }

        // 표본수 자동계산 (모든 통제)
        function autoCalculateSampleSizes() {
            if (!confirm('모든 통제의 표본수를 통제주기 기준으로 자동 계산하시겠습니까?\n\n기존에 입력된 값도 모두 덮어씌워집니다.')) {
                return;
            }

            let updatedCount = 0;
            let errorCount = 0;

            // 모든 표본수 입력 필드 찾기
            const sampleSizeInputs = document.querySelectorAll('.sample-size-input');

            sampleSizeInputs.forEach(input => {
                const controlFrequency = input.getAttribute('data-control-frequency');
                const detailId = input.getAttribute('data-detail-id');

                if (!detailId) {
                    return; // detail_id가 없으면 건너뛰기
                }

                // 통제주기에 따른 기본 표본수 계산
                const defaultSize = getDefaultSampleSize(controlFrequency);

                // 입력 필드에 값 설정
                input.value = defaultSize;

                // 서버에 저장
                const sampleSize = defaultSize || null;

                fetch(`/rcm/detail/${detailId}/sample-size`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        recommended_sample_size: sampleSize
                    })
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        updatedCount++;
                        // data-original-value 업데이트
                        input.setAttribute('data-original-value', sampleSize || '');
                    } else {
                        errorCount++;
                        console.error('저장 실패:', data.message);
                    }

                    // 모든 요청 완료 후 결과 표시
                    if (updatedCount + errorCount === sampleSizeInputs.length) {
                        if (errorCount > 0) {
                            showToast(`${updatedCount}개 저장 완료, ${errorCount}개 실패`, 'warning');
                        } else {
                            showToast(`${updatedCount}개의 표본수가 자동 계산되어 저장되었습니다.`, 'success');
                        }
                    }
                })
                .catch(error => {
                    errorCount++;
                    console.error('저장 오류:', error);

                    // 모든 요청 완료 후 결과 표시
                    if (updatedCount + errorCount === sampleSizeInputs.length) {
                        showToast(`${updatedCount}개 저장 완료, ${errorCount}개 실패`, 'error');
                    }
                });
            });
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

        // Excel 다운로드 기능
        function exportToExcel() {
            const table = document.getElementById('rcmTable');
            const wb = XLSX.utils.table_to_book(table, {sheet: "RCM 상세"});
            const fileName = '{{ rcm_info.rcm_name }}_상세보기.xlsx';
            XLSX.writeFile(wb, fileName);
        }

        // 변경사항 통합 저장 기능
        // 툴팁 초기화
        document.addEventListener('DOMContentLoaded', function() {
            // 기준통제 모달 초기화
            const stdModalEl = document.getElementById('stdControlModal');
            if (stdModalEl) {
                stdControlModalInstance = new bootstrap.Modal(stdModalEl);
            }

            // 기준통제 검색 기능
            const searchInput = document.getElementById('std-control-search');
            if (searchInput) {
                searchInput.addEventListener('input', function() {
                    filterStdControls(this.value);
                });
            }

            // 매핑 해제 버튼
            const unmapBtn = document.getElementById('btn-unmap-std-control');
            if (unmapBtn) {
                unmapBtn.addEventListener('click', unmapStdControl);
            }

            var tooltipTriggerList = [].slice.call(document.querySelectorAll('[title]'));
            var tooltipList = tooltipTriggerList.map(function(tooltipTriggerEl) {
                return new bootstrap.Tooltip(tooltipTriggerEl);
            });

            document.querySelectorAll('.editable-cell').forEach(cell => {
                cell.addEventListener('keydown', function(e) {
                    // Enter 키를 누르면 줄바꿈 문자를 삽입
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault(); // 기본 동작(div/p 태그 생성) 방지
                        document.execCommand('insertLineBreak');
                    }
                });
            });

            document.querySelectorAll('.editable-cell').forEach(cell => {
                cell.addEventListener('blur', function() {
                    if (this.textContent.trim() === '') {
                        this.textContent = '-';
                    }
                });

                cell.addEventListener('focus', function() {
                    if (this.textContent.trim() === '-') {
                        this.textContent = '';
                    }
                });
            });

            document.querySelectorAll('.sample-size-input').forEach(input => {
                // placeholder는 이미 HTML에서 "자동"으로 설정되어 있음
                // 자동 계산 값은 표시하지 않음 (공란으로 유지)

                // 숫자만 입력 가능하도록 제한 (입력 중)
                input.addEventListener('keypress', function(e) {
                    // 숫자(0-9)만 허용
                    if (e.key < '0' || e.key > '9') {
                        e.preventDefault();
                    }
                });

                // 붙여넣기 시 숫자만 허용
                input.addEventListener('paste', function(e) {
                    e.preventDefault();
                    const pastedText = (e.clipboardData || window.clipboardData).getData('text');
                    const numbersOnly = pastedText.replace(/\D/g, '');
                    if (numbersOnly) {
                        this.value = numbersOnly.slice(0, 3);  // 최대 3자리
                        // 붙여넣기 후 자동 저장
                        saveSampleSize(this);
                    }
                });

                // 입력 값 유효성 검사 및 자동 저장 (blur 이벤트)
                input.addEventListener('blur', function() {
                    const value = parseInt(this.value);
                    const originalValue = this.getAttribute('data-original-value') || '';
                    const currentValue = this.value.trim();

                    // 유효성 검사
                    if (currentValue !== '' && (isNaN(value) || value < 0 || value > 100)) {
                        showToast('표본수는 0~100 사이의 값이거나 공란이어야 합니다.', 'error');
                        this.value = originalValue;  // 원래 값으로 복원
                        return;
                    }

                    // 값이 변경되었으면 자동 저장
                    if (originalValue !== currentValue) {
                        saveSampleSize(this);
                    }
                });
            });
        });

        // 표본수 자동 저장 함수
        function saveSampleSize(input) {
            const detailId = input.getAttribute('data-detail-id');
            const sampleSize = input.value.trim() === '' ? null : parseInt(input.value);
            const originalValue = input.getAttribute('data-original-value') || '';

            // 유효하지 않은 detail_id는 건너뛰기
            if (!detailId || detailId === 'None' || detailId === 'null' || detailId.trim() === '') {
                console.error('유효하지 않은 detail_id:', detailId);
                return;
            }

            // 저장 중 표시
            input.style.backgroundColor = '#fff3cd';
            input.disabled = true;

            fetch(`/rcm/detail/${detailId}/sample-size`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    recommended_sample_size: sampleSize
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // 저장 성공
                    input.setAttribute('data-original-value', sampleSize === null ? '' : sampleSize.toString());
                    input.style.backgroundColor = '#d4edda';  // 성공 색상
                    setTimeout(() => {
                        input.style.backgroundColor = '';
                    }, 1000);
                } else {
                    // 저장 실패
                    showToast('저장 실패: ' + (data.message || '알 수 없는 오류'), 'error');
                    input.value = originalValue;  // 원래 값으로 복원
                    input.style.backgroundColor = '';
                }
            })
            .catch(error => {
                console.error('저장 오류:', error);
                showToast('저장 중 오류가 발생했습니다.', 'error');
                input.value = originalValue;  // 원래 값으로 복원
                input.style.backgroundColor = '';
            })
            .finally(() => {
                input.disabled = false;
            });
        }

        // 통제활동 설명 모달 관련 변수
        let controlDescriptionModalInstance = null;

        // 통제활동 설명 모달 열기
        function showControlDescriptionModal(controlCode, controlName, controlDescription) {
            // 모달 정보 표시
            document.getElementById('desc-modal-control-code').textContent = controlCode;
            document.getElementById('desc-modal-control-name').textContent = controlName;
            document.getElementById('desc-modal-description').textContent = controlDescription || '-';

            // 모달 표시
            const modalEl = document.getElementById('controlDescriptionModal');
            if (!controlDescriptionModalInstance) {
                controlDescriptionModalInstance = new bootstrap.Modal(modalEl);
            }
            controlDescriptionModalInstance.show();
        }

        // 테스트 절차 모달 관련 변수
        let testProcedureModalInstance = null;

        // 테스트 절차 모달 열기
        function showTestProcedureModal(controlCode, controlName, testProcedure) {
            // 모달 정보 표시
            document.getElementById('test-modal-control-code').textContent = controlCode;
            document.getElementById('test-modal-control-name').textContent = controlName;
            document.getElementById('test-modal-procedure').textContent = testProcedure || '-';

            // 모달 표시
            const modalEl = document.getElementById('testProcedureModal');
            if (!testProcedureModalInstance) {
                testProcedureModalInstance = new bootstrap.Modal(modalEl);
            }
            testProcedureModalInstance.show();
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

        // 모집단 항목 수 유효성 검사
        function validatePopCount() {
            const input = document.getElementById('population-attr-count');
            let value = parseInt(input.value);

            if (isNaN(value) || value < 0) {
                input.value = 0;
            } else if (value > 10) {
                input.value = 10;
            }
            updateAttributeStyles();
        }

        // Attribute 스타일 업데이트 (모집단/증빙 구분)
        function updateAttributeStyles() {
            const popCount = parseInt(document.getElementById('population-attr-count').value) || 0;

            for (let i = 0; i < 10; i++) {
                const row = document.querySelector(`.attribute-row[data-index="${i}"]`);
                const badge = document.querySelector(`.attribute-type-badge[data-index="${i}"]`);

                if (row && badge) {
                    if (i < popCount) {
                        // 모집단 영역
                        row.style.backgroundColor = '#e7f3ff';
                        badge.className = 'badge bg-primary attribute-type-badge';
                        badge.textContent = '모집단';
                    } else {
                        // 증빙 영역
                        row.style.backgroundColor = '#fff9e6';
                        badge.className = 'badge bg-warning attribute-type-badge';
                        badge.textContent = '증빙';
                    }
                }
            }
        }

        // 기존 attribute 값 로드
        function loadAttributes(detailId) {
            fetch(`/api/rcm/detail/${detailId}/attributes`)
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

                        // 스타일 업데이트
                        updateAttributeStyles();
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
            let populationAttributeCount = popCountInput ? parseInt(popCountInput.value) : 2;

            // 유효하지 않은 값(NaN, 음수) 체크 - 0은 허용 (자동통제의 경우 모집단 없음)
            if (isNaN(populationAttributeCount) || populationAttributeCount < 0) {
                console.warn('[saveAttributes] Invalid population_attribute_count:', popCountInput?.value, 'Using default: 2');
                populationAttributeCount = 2;
            }
            console.log('[saveAttributes] population_attribute_count:', populationAttributeCount);

            // 서버에 저장
            fetch(`/api/rcm/detail/${currentDetailId}/attributes`, {
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

        // 기준통제 선택 모달 열기
        function openStdControlModal(rcmDetailId, controlCode, currentStdControlId) {
            currentMappingRcmDetailId = rcmDetailId;
            currentMappingControlCode = controlCode;

            document.getElementById('std-modal-control-code').textContent = controlCode;

            // 매핑 해제 버튼 표시 여부
            const unmapBtn = document.getElementById('btn-unmap-std-control');
            if (currentStdControlId) {
                unmapBtn.style.display = 'inline-block';
            } else {
                unmapBtn.style.display = 'none';
            }

            // 기준통제 목록 로드
            loadStdControls(currentStdControlId);

            // 모달 표시
            stdControlModalInstance.show();
        }

        // 기준통제 목록 로드
        function loadStdControls(currentStdControlId) {
            fetch('/api/standard-controls')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        allStdControls = data.standard_controls;
                        renderStdControls(allStdControls, currentStdControlId);
                    } else {
                        showToast('기준통제 목록 로드 실패', 'error');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showToast('기준통제 목록 로드 중 오류 발생', 'error');
                });
        }

        // 기준통제 목록 렌더링
        function renderStdControls(controls, currentStdControlId) {
            const tbody = document.getElementById('std-control-list');
            if (!controls || controls.length === 0) {
                tbody.innerHTML = '<tr><td colspan="3" class="text-center">기준통제가 없습니다.</td></tr>';
                return;
            }

            tbody.innerHTML = controls.map(ctrl => {
                const isSelected = ctrl.std_control_id == currentStdControlId;
                const rowClass = isSelected ? 'table-primary' : '';
                const badge = isSelected ? '<span class="badge bg-primary ms-2">현재 매핑됨</span>' : '';

                return `
                    <tr class="${rowClass}" style="cursor: pointer;" onclick="selectStdControl(${ctrl.std_control_id})">
                        <td><span class="badge bg-info">${ctrl.control_category}</span></td>
                        <td><code>${ctrl.control_code}</code></td>
                        <td>${ctrl.control_name}${badge}</td>
                    </tr>
                `;
            }).join('');
        }

        // 기준통제 검색 필터
        function filterStdControls(searchText) {
            if (!searchText.trim()) {
                renderStdControls(allStdControls, null);
                return;
            }

            const filtered = allStdControls.filter(ctrl => {
                const text = searchText.toLowerCase();
                return ctrl.control_code.toLowerCase().includes(text) ||
                       ctrl.control_name.toLowerCase().includes(text) ||
                       ctrl.control_category.toLowerCase().includes(text);
            });

            renderStdControls(filtered, null);
        }

        // 기준통제 선택 (매핑)
        function selectStdControl(stdControlId) {
            if (!currentMappingRcmDetailId) {
                showToast('오류: RCM Detail ID가 없습니다.', 'error');
                return;
            }

            fetch(`/api/rcm-detail/${currentMappingRcmDetailId}/map-standard-control`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    std_control_id: stdControlId
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showToast('기준통제 매핑이 완료되었습니다.', 'success');
                    stdControlModalInstance.hide();
                    location.reload(); // 페이지 새로고침하여 변경사항 반영
                } else {
                    showToast('매핑 실패: ' + (data.message || '알 수 없는 오류'), 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showToast('매핑 중 오류가 발생했습니다.', 'error');
            });
        }

        // 기준통제 매핑 해제
        function unmapStdControl() {
            if (!currentMappingRcmDetailId) {
                showToast('오류: RCM Detail ID가 없습니다.', 'error');
                return;
            }

            if (!confirm('기준통제 매핑을 해제하시겠습니까?')) {
                return;
            }

            fetch(`/api/rcm-detail/${currentMappingRcmDetailId}/unmap-standard-control`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showToast('기준통제 매핑이 해제되었습니다.', 'success');
                    stdControlModalInstance.hide();
                    location.reload(); // 페이지 새로고침하여 변경사항 반영
                } else {
                    showToast('매핑 해제 실패: ' + (data.message || '알 수 없는 오류'), 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showToast('매핑 해제 중 오류가 발생했습니다.', 'error');
            });
        }

    </script>
</body>
</html>