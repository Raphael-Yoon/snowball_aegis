<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <!-- 다크모드 FOUC 방지 -->
    <script>
        (function() {
            var theme = localStorage.getItem('snowball-theme') || 'light';
            document.documentElement.setAttribute('data-bs-theme', theme);
        })();
    </script>
    <title>Snowball - {{ evaluation_type|default('ITGC') }} 설계평가 - {{ rcm_info.rcm_name }}</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        html[data-bs-theme="dark"] .alert-guide-info,
        html[data-bs-theme="dark"] .alert-guide-info * {
            color: #000000 !important;
        }
    </style>
</head>

<body>
    {% include 'navi.jsp' %}

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h1><i class="fas fa-clipboard-check me-2"></i>{{ evaluation_type|default('ITGC') }} 설계평가</h1>
                        <div id="evaluationNameDisplay" class="text-primary fw-bold fs-6 mt-1" style="display: none;">
                            평가명: <span id="currentEvaluationName"></span>
                        </div>
                    </div>
                    <div class="d-flex gap-2">
                        {% if has_operation_evaluation %}
                        <button type="button" class="btn btn-warning" onclick="viewOperationEvaluation()">
                            <i class="fas fa-chart-line me-1"></i>운영평가 보기
                        </button>
                        {% endif %}
                        {% if evaluation_type == 'ELC' %}
                        <a href="{{ url_for('link6.elc_design_evaluation') }}" class="btn btn-secondary">
                            <i class="fas fa-arrow-left me-1"></i>목록으로
                        </a>
                        {% elif evaluation_type == 'TLC' %}
                        <a href="{{ url_for('link6.tlc_evaluation') }}" class="btn btn-secondary">
                            <i class="fas fa-arrow-left me-1"></i>목록으로
                        </a>
                        {% elif evaluation_type == 'ITGC' %}
                        <a href="{{ url_for('link6.itgc_evaluation') }}" class="btn btn-secondary">
                            <i class="fas fa-arrow-left me-1"></i>목록으로
                        </a>
                        {% else %}
                        <a href="/user/design-evaluation" class="btn btn-secondary">
                            <i class="fas fa-arrow-left me-1"></i>목록으로
                        </a>
                        {% endif %}
                    </div>
                </div>
                <hr>
            </div>
        </div>

        <!-- RCM 기본 정보 -->
        <div class="row mb-3">
            <div class="col-12">
                <div class="card border-success">
                    <div class="card-header bg-success text-white py-2">
                        <h5 class="mb-0"><i class="fas fa-info-circle me-2"></i>RCM 기본 정보</h5>
                    </div>
                    <div class="card-body py-3">
                        <div class="row align-items-center">
                            <div class="col-md-4">
                                <table class="table table-borderless table-sm mb-0">
                                    <tr>
                                        <th width="40%">RCM명:</th>
                                        <td><strong>{{ rcm_info.rcm_name }}</strong></td>
                                    </tr>
                                    <tr>
                                        <th>회사명:</th>
                                        <td>{{ rcm_info.company_name }}</td>
                                    </tr>
                                </table>
                            </div>
                            <div class="col-md-4">
                                <table class="table table-borderless table-sm mb-0">
                                    <tr>
                                        <th width="40%">총 통제 수:</th>
                                        <td><span class="badge bg-primary">{{ rcm_details|length }}개</span></td>
                                    </tr>
                                    <tr>
                                        <th>평가자:</th>
                                        <td><strong>{{ user_info.user_name }}</strong></td>
                                    </tr>
                                </table>
                            </div>
                            <div class="col-md-4">
                                <div class="text-center">
                                    <h6 class="text-success mb-2">설계평가 진행률</h6>
                                    <div class="progress mb-2" style="height: 20px;">
                                        <div class="progress-bar bg-success" id="evaluationProgress" role="progressbar"
                                            style="width: 0%; font-size: 12px;" aria-valuenow="0" aria-valuemin="0"
                                            aria-valuemax="100">0%</div>
                                    </div>
                                    <small class="text-muted">
                                        <span id="evaluatedCount">0</span> / <span id="totalControlCount">{{
                                            rcm_details|length }}</span> 통제 평가 완료
                                    </small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 설계평가 통제 목록 -->
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5><i class="fas fa-list me-2"></i>통제 설계평가</h5>
                        <div class="d-flex flex-wrap gap-2">
                            {% if user_info.admin_flag == 'Y' %}
                            <button class="btn btn-sm btn-outline-primary" onclick="saveAllAsAdequate()"
                                title="[관리자 전용] 모든 통제를 '적정' 값으로 실제 저장" data-bs-toggle="tooltip"
                                style="height: 70%; padding: 0.2rem 0.5rem; border: 2px dashed #0d6efd;">
                                <i class="fas fa-user-shield me-1"></i><i class="fas fa-check-circle me-1"></i>적정저장
                            </button>
                            <button class="btn btn-sm btn-outline-warning" onclick="resetAllEvaluations()"
                                title="[관리자 전용] 모든 설계평가 데이터 초기화" data-bs-toggle="tooltip"
                                style="height: 70%; padding: 0.2rem 0.5rem; border: 2px dashed #ffc107;">
                                <i class="fas fa-user-shield me-1"></i><i class="fas fa-undo me-1"></i>초기화
                            </button>
                            {% endif %}
                            <button id="completeEvaluationBtn" class="btn btn-sm btn-success"
                                onclick="completeEvaluation()"
                                style="display: none; height: 70%; padding: 0.2rem 0.5rem; width: auto;"
                                title="설계평가를 완료 처리합니다" data-bs-toggle="tooltip">
                                <i class="fas fa-check me-1"></i>완료
                            </button>
                            <button id="archiveEvaluationBtn" class="btn btn-sm btn-secondary"
                                onclick="archiveEvaluation()"
                                style="display: none; height: 70%; padding: 0.2rem 0.5rem;"
                                title="완료된 설계평가를 Archive 처리합니다" data-bs-toggle="tooltip">
                                <i class="fas fa-archive me-1"></i>Archive
                            </button>
                            <button id="downloadBtn" class="btn btn-sm btn-outline-primary"
                                onclick="downloadDesignEvaluation()"
                                style="display: none; height: 70%; padding: 0.2rem 0.5rem;"
                                title="설계평가 결과를 Excel로 다운로드합니다" data-bs-toggle="tooltip">
                                <i class="fas fa-file-excel me-1"></i>다운로드
                            </button>
                            <button class="btn btn-sm btn-outline-secondary" onclick="refreshEvaluationList()"
                                style="height: 70%; padding: 0.2rem 0.5rem;" title="평가 목록 새로고침"
                                data-bs-toggle="tooltip">
                                <i class="fas fa-sync-alt me-1"></i>새로고침
                            </button>
                        </div>
                    </div>
                    <div class="card-body">
                        {% if rcm_details %}
                        <div class="table-responsive">
                            <table class="table table-striped align-middle" id="controlsTable">
                                <thead>
                                    <tr>
                                        <th width="6%">통제코드</th>
                                        <th width="12%">통제명</th>
                                        <th width="32%">통제활동설명</th>
                                        <th width="7%" class="text-center">통제주기</th>
                                        <th width="5%" class="text-center">통제유형</th>
                                        <th width="5%" class="text-center">핵심통제</th>
                                        {% if evaluation_type == 'ITGC' %}
                                        <th width="8%">기준통제 매핑</th>
                                        {% endif %}
                                        <th width="5%" class="text-center" style="max-width: 60px;">평가</th>
                                        <th width="5%" class="text-center">평가결과</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for detail in rcm_details %}
                                    {% set mapping_info = rcm_mappings|selectattr('control_code', 'equalto',
                                    detail.control_code)|first %}
                                    <tr id="control-row-{{ loop.index }}" {% if evaluation_type=='ITGC' and not
                                        mapping_info %}class="table-warning" {% endif %}>
                                        <td><code>{{ detail.control_code }}</code></td>
                                        <td><strong>{{ detail.control_name }}</strong></td>
                                        <td>
                                            <div style="display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; text-overflow: ellipsis; line-height: 1.4; max-height: calc(1.4em * 2);"
                                                title="{{ detail.control_description or '-' }}"
                                                data-bs-toggle="tooltip">
                                                {{ detail.control_description or '-' }}
                                            </div>
                                        </td>
                                        <td class="text-center">{{ detail.control_frequency or '-' }}</td>
                                        <td class="text-center">{{ detail.control_type or '-' }}</td>
                                        <td class="text-center">
                                            {{ detail.key_control or '비핵심' }}
                                        </td>
                                        {% if evaluation_type == 'ITGC' %}
                                        <td>
                                            {% if mapping_info %}
                                            <a href="javascript:void(0)"
                                                onclick="openStdControlModal({{ detail.detail_id }}, '{{ detail.control_code }}', {{ mapping_info.std_control_id or 'null' }})"
                                                class="badge bg-success text-white text-decoration-none"
                                                title="{{ mapping_info.std_control_name or mapping_info.std_control_code or '기준통제 매핑됨' }}"
                                                data-bs-toggle="tooltip">
                                                <i class="fas fa-link me-1"></i>매핑
                                            </a>
                                            {% else %}
                                            <a href="javascript:void(0)"
                                                onclick="openStdControlModal({{ detail.detail_id }}, '{{ detail.control_code }}', null)"
                                                class="badge bg-warning text-dark fw-bold text-decoration-none"
                                                style="border: 2px solid #fd7e14;" title="클릭하여 기준통제 매핑하기"
                                                data-bs-toggle="tooltip">
                                                <i class="fas fa-exclamation-triangle me-1"></i>매핑안됨
                                            </a>
                                            {% endif %}
                                        </td>
                                        {% endif %}
                                        <td style="text-align: center; padding: 0.25rem;">
                                            <button class="btn btn-sm btn-outline-success evaluate-btn"
                                                onclick="openEvaluationModal({{ loop.index }}, '{{ detail.control_code }}', '{{ detail.control_name }}')"
                                                id="eval-btn-{{ loop.index }}"
                                                style="padding: 0.2rem 0.5rem; font-size: 0.75rem; min-width: 60px; white-space: nowrap;">
                                                <i class="fas fa-edit me-1"></i>평가
                                            </button>
                                        </td>
                                        <td class="text-center">
                                            <span class="evaluation-result" id="result-{{ loop.index }}">
                                                <span class="text-muted"></span>
                                            </span>
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
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 설계평가 모달 -->
    <div class="modal fade" id="evaluationModal" tabindex="-1">
        <div class="modal-dialog modal-xl">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-clipboard-check me-2"></i>통제 설계평가
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <!-- 통제 기본 정보 -->
                    <div class="card mb-4">
                        <div class="card-header bg-light">
                            <h6 class="mb-0"><i class="fas fa-info-circle me-2"></i>통제 기본 정보</h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <table class="table table-borderless mb-0">
                                        <tr>
                                            <th style="width: 100px; white-space: nowrap; vertical-align: top;">통제코드:
                                            </th>
                                            <td style="vertical-align: top;">
                                                <span id="modalControlCode" class="text-primary fw-bold"></span>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style="width: 100px; white-space: nowrap; vertical-align: top;">통제명:
                                            </th>
                                            <td style="vertical-align: top;">
                                                <span id="modalControlName" class="fw-bold"></span>
                                            </td>
                                        </tr>
                                    </table>
                                </div>
                                <div class="col-md-6">
                                    <table class="table table-borderless mb-0">
                                        <tr>
                                            <th style="width: 100px; white-space: nowrap; vertical-align: top;">통제주기:
                                            </th>
                                            <td style="vertical-align: top;">
                                                <span id="modalControlFrequency" class="text-muted"></span>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style="width: 100px; white-space: nowrap; vertical-align: top;">통제유형:
                                            </th>
                                            <td style="vertical-align: top;">
                                                <span id="modalControlType" class="text-muted"></span>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th style="width: 100px; white-space: nowrap; vertical-align: top;">통제구분:
                                            </th>
                                            <td style="vertical-align: top;">
                                                <span id="modalControlNature" class="text-muted"></span>
                                            </td>
                                        </tr>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 통제활동 설명 검토 -->
                    <div class="card mb-4">
                        <div class="card-header bg-warning text-dark">
                            <h6 class="mb-0"><i class="fas fa-search me-2"></i>통제활동 설명 검토</h6>
                        </div>
                        <div class="card-body">
                            <div class="mb-3">
                                <label class="form-label"><strong>현재 통제활동 설명:</strong></label>
                                <div class="p-3 bg-light border rounded">
                                    <p id="modalControlDescription" class="mb-0"></p>
                                </div>
                            </div>

                            <div class="alert alert-guide-info">
                                <i class="fas fa-lightbulb me-2"></i>
                                <strong>평가 기준:</strong> 위에 기술된 통제활동이 현재 실제로 수행되고 있는 통제 절차와 일치하는지, 그리고 해당 통제가 실무적으로 효과적으로
                                작동하고 있는지 평가하세요.
                            </div>

                            <div class="mb-3">
                                <label for="descriptionAdequacy" class="form-label">통제활동 현실 반영도 *</label>
                                <select class="form-select" id="descriptionAdequacy" required>
                                    <option value="">평가 결과 선택</option>
                                    <option value="adequate">적절함 - 실제 수행 절차와 완전히 일치함</option>
                                    <option value="partially_adequate">부분적으로 적절함 - 실제와 일부 차이가 있음</option>
                                    <option value="inadequate">부적절함 - 실제 절차와 상당한 차이가 있음</option>
                                    <option value="missing">누락 - 통제활동이 실제로 수행되지 않음</option>
                                </select>
                            </div>

                            <div class="mb-3">
                                <label for="improvementSuggestion" class="form-label">개선 제안사항</label>
                                <textarea class="form-control" id="improvementSuggestion" rows="3"
                                    placeholder="실제 업무와 차이가 있는 경우, RCM 문서 업데이트 방향이나 실무 개선 방안을 제안하세요..."></textarea>
                            </div>
                        </div>
                    </div>

                    <!-- 설계 효과성 종합 평가 -->
                    <div class="card mb-3" id="effectivenessSection">
                        <div class="card-header bg-success text-white">
                            <h6 class="mb-0"><i class="fas fa-check-circle me-2"></i>설계 효과성 종합 평가</h6>
                        </div>
                        <div class="card-body">
                            <!-- 해당 없음 (통제 미시행) 옵션 -->
                            <div class="mb-3" id="no-occurrence-section-design">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="no_occurrence_design"
                                        name="no_occurrence_design" onchange="
                                               console.log('체크박스 클릭됨');
                                               const checked = this.checked;
                                               console.log('체크 상태:', checked);
                                               document.getElementById('design-evidence-section').style.display = checked ? 'none' : 'block';
                                               document.getElementById('recommended-actions-section').style.display = checked ? 'none' : 'block';
                                               document.getElementById('design-comment-section').style.display = checked ? 'none' : 'block';
                                               document.getElementById('evaluation-images-section').style.display = checked ? 'none' : 'block';
                                               document.getElementById('no-occurrence-reason-section-design').style.display = checked ? 'block' : 'none';
                                           ">
                                    <label class="form-check-label" for="no_occurrence_design">
                                        <strong>해당 없음 (통제 미시행)</strong>
                                        <small class="text-muted d-block">평가 기간 동안 해당 통제가 아직 시행되지 않은 경우 체크하세요</small>
                                    </label>
                                </div>
                            </div>

                            <!-- 통제 미시행 사유 -->
                            <div class="mb-3" id="no-occurrence-reason-section-design" style="display: none;">
                                <label for="no_occurrence_reason_design" class="form-label fw-bold">
                                    미시행 사유
                                </label>
                                <textarea class="form-control" id="no_occurrence_reason_design"
                                    name="no_occurrence_reason_design" rows="3"
                                    placeholder="통제가 미시행된 사유를 입력하세요&#10;예) 분기 통제로 평가 시점에 아직 시행 전, 시스템 도입 예정, 신규 통제로 시행 준비 중 등"></textarea>
                            </div>

                            <div class="mb-3" id="design-evidence-section">
                                <label class="form-label">증빙 및 결과</label>
                                <div class="table-responsive">
                                    <table class="table table-bordered table-sm" id="designEvidenceTable">
                                        <thead class="table-light" id="design-evidence-thead">
                                            <!-- 동적 생성 -->
                                        </thead>
                                        <tbody id="design-evidence-tbody">
                                            <!-- 동적 생성 -->
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <div class="mb-3" id="evaluation-images-section">
                                <label for="evaluationImages" class="form-label">평가 증빙 자료 (이미지)</label>
                                <div id="imageUploadSection">
                                    <input type="file" class="form-control" id="evaluationImages" accept="image/*"
                                        multiple>
                                    <div class="form-text">현장 사진, 스크린샷, 문서 스캔본 등 평가 근거가 되는 이미지 파일을 첨부하세요. (다중 선택 가능)
                                    </div>
                                </div>
                                <div id="imagePreview" class="mt-2" style="width: 100%;"></div>
                            </div>

                            <div class="mb-3" id="design-comment-section">
                                <label for="designComment" class="form-label">설계 평가 코멘트</label>
                                <textarea class="form-control" id="designComment" rows="3"
                                    placeholder="설계 효과성에 대한 종합적인 의견이나 특이사항을 입력하세요..."></textarea>
                            </div>

                            <div class="mb-3" id="recommended-actions-section">
                                <label for="recommendedActions" class="form-label">권고 조치사항</label>
                                <textarea class="form-control" id="recommendedActions" rows="2"
                                    placeholder="실무와 문서 간 차이 해소나 통제 운영 개선을 위한 구체적인 조치사항을 제안하세요..."></textarea>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-outline-secondary" data-bs-dismiss="modal"
                        style="padding: 0.25rem 0.5rem; font-size: 0.875rem;">
                        <i class="fas fa-times me-1"></i>닫기
                    </button>
                    <button type="button" id="saveEvaluationBtn" class="btn btn-sm btn-success"
                        onclick="saveEvaluation()" style="padding: 0.25rem 0.5rem; font-size: 0.875rem;">
                        <i class="fas fa-save me-1"></i>평가 저장
                    </button>
                </div>
            </div>
        </div>
    </div>


    <!-- 샘플 업로드 모달 -->
    <div class="modal fade" id="sampleUploadModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-upload me-2"></i>설계평가 샘플 업로드
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="alert alert-guide-info">
                        <i class="fas fa-info-circle me-2"></i>
                        <strong>업로드 안내:</strong> 설계평가 결과가 포함된 CSV 또는 Excel 파일을 업로드하여 일괄 적용할 수 있습니다.
                    </div>

                    <!-- 파일 업로드 -->
                    <div class="mb-4">
                        <label for="evaluationFile" class="form-label">평가 결과 파일 선택</label>
                        <input class="form-control" type="file" id="evaluationFile" accept=".csv,.xlsx,.xls">
                        <div class="form-text">지원 형식: CSV, Excel (.xlsx, .xls)</div>
                    </div>

                    <!-- 파일 형식 가이드 -->
                    <div class="mb-4">
                        <h6><i class="fas fa-table me-2"></i>파일 형식 가이드</h6>
                        <div class="table-responsive">
                            <table class="table table-sm table-bordered">
                                <thead>
                                    <tr class="table-light">
                                        <th>통제코드</th>
                                        <th>설명적절성</th>
                                        <th>개선제안</th>
                                        <th>종합효과성</th>
                                        <th>평가근거</th>
                                        <th>권고조치사항</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>C001</td>
                                        <td>adequate</td>
                                        <td>개선사항 없음</td>
                                        <td>effective</td>
                                        <td>통제가 적절히 설계됨</td>
                                        <td>현행 유지</td>
                                    </tr>
                                    <tr class="table-light">
                                        <td colspan="6" class="text-center small text-muted">
                                            설명적절성: adequate/partially_adequate/inadequate/missing<br>
                                            종합효과성: effective/partially_effective/ineffective
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- 샘플 파일 다운로드 -->
                    <div class="mb-3">
                        <h6><i class="fas fa-download me-2"></i>샘플 파일</h6>
                        <button class="btn btn-sm btn-outline-primary" onclick="downloadSampleTemplate()">
                            <i class="fas fa-file-csv me-1"></i>샘플 템플릿 다운로드
                        </button>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal"
                        style="padding: 0.25rem 0.5rem; font-size: 0.875rem;">
                        <i class="fas fa-times me-1"></i>닫기
                    </button>
                    <button type="button" class="btn btn-sm btn-info" onclick="uploadEvaluationFile()"
                        style="padding: 0.25rem 0.5rem; font-size: 0.875rem;">
                        <i class="fas fa-upload me-1"></i>업로드 및 적용
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
                    <div class="alert alert-guide-info">
                        <i class="fas fa-info-circle me-2"></i>
                        매핑할 기준통제를 선택하세요. 선택한 기준통제의 Attribute 템플릿이 자동으로 적용됩니다.
                    </div>
                    <div class="mb-3">
                        <input type="text" class="form-control" id="std-control-search"
                            placeholder="기준통제 코드 또는 이름으로 검색...">
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

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

    <!-- 설계평가 JavaScript -->
    <script>
        let currentEvaluationIndex = null;
        let evaluationResults = {};
        let evaluationImages = {}; // 평가별 이미지 저장
        const rcmId = {{ rcm_id }};

        console.log('***** JavaScript rcmId value:', rcmId, '(type:', typeof rcmId, ') *****');

        // RCM Attribute 정보 저장 (운영평가와 동일한 구조)
        let rcmAttributesData = {};
        {% if rcm_details %}
        {% for detail in rcm_details %}
        rcmAttributesData[{{ detail['control_code'] | tojson }}] = {
            detailId: {{ detail['detail_id'] | int }},
            populationAttributeCount: {{ detail['population_attribute_count'] | int if detail['population_attribute_count'] is not none else 2 }},
            attributes: {
                attribute0: {{ detail['attribute0'] | tojson if detail['attribute0'] else 'null' }},
                attribute1: {{ detail['attribute1'] | tojson if detail['attribute1'] else 'null' }},
                attribute2: {{ detail['attribute2'] | tojson if detail['attribute2'] else 'null' }},
                attribute3: {{ detail['attribute3'] | tojson if detail['attribute3'] else 'null' }},
                attribute4: {{ detail['attribute4'] | tojson if detail['attribute4'] else 'null' }},
                attribute5: {{ detail['attribute5'] | tojson if detail['attribute5'] else 'null' }},
                attribute6: {{ detail['attribute6'] | tojson if detail['attribute6'] else 'null' }},
                attribute7: {{ detail['attribute7'] | tojson if detail['attribute7'] else 'null' }},
                attribute8: {{ detail['attribute8'] | tojson if detail['attribute8'] else 'null' }},
                attribute9: {{ detail['attribute9'] | tojson if detail['attribute9'] else 'null' }}
            }
        };
        {% endfor %}
        {% endif %}

        console.log('[Design Evaluation] RCM Attributes Data:', rcmAttributesData);

        // 설계평가 증빙 테이블 동적 생성 (Attribute 기반)
        function generateDesignEvidenceTable(controlCode) {
            console.log('[generateDesignEvidenceTable] controlCode:', controlCode);

            const thead = document.getElementById('design-evidence-thead');
            const tbody = document.getElementById('design-evidence-tbody');

            if (!thead || !tbody) {
                console.error('[generateDesignEvidenceTable] Table elements not found');
                return;
            }

            // RCM attribute 정보 가져오기
            const attrData = rcmAttributesData[controlCode];
            if (!attrData) {
                console.log('[generateDesignEvidenceTable] No attribute data for control:', controlCode);
                // Attribute가 없으면 기본 증빙 컬럼만 표시
                thead.innerHTML = `<tr>
                    <th width="10%">표본 #</th>
                    <th width="70%">증빙 내용</th>
                    <th width="20%">결과</th>
                </tr>`;
                tbody.innerHTML = `<tr>
                    <td class="text-center align-middle">#1</td>
                    <td class="align-middle">
                        <input type="text" class="form-control form-control-sm"
                               id="evaluationEvidence"
                               placeholder="평가 시 확인한 증빙 자료를 입력하세요"
                               style="height: 31px;" />
                    </td>
                    <td class="align-middle">
                        <select class="form-select form-select-sm"
                                id="overallEffectiveness"
                                required disabled
                                style="height: 31px;">
                            <option value="">선택</option>
                            <option value="effective">효과적</option>
                            <option value="ineffective">비효과적</option>
                        </select>
                    </td>
                </tr>`;
                return;
            }

            // 0도 유효한 값이므로 null/undefined만 체크
            const popAttrCount = attrData.populationAttributeCount !== null && attrData.populationAttributeCount !== undefined ? attrData.populationAttributeCount : 2;
            const attributes = attrData.attributes || {};

            console.log('[generateDesignEvidenceTable] popAttrCount:', popAttrCount);
            console.log('[generateDesignEvidenceTable] attributes:', attributes);

            // 설정된 attribute가 있는지 확인
            const hasAttributes = Object.values(attributes).some(v => v);

            // 테이블 헤더 생성
            let headerHtml = '<tr><th width="10%">표본 #</th>';

            if (hasAttributes) {
                // Attribute 컬럼 추가 (모집단/증빙 구분 표시)
                for (let i = 0; i < 10; i++) {
                    const attrName = attributes[`attribute${i}`];
                    if (attrName) {
                        const isPopulation = i < popAttrCount;
                        const badge = isPopulation
                            ? '<span class="badge bg-primary ms-1" style="font-size: 0.7em;">모집단</span>'
                            : '<span class="badge bg-success ms-1" style="font-size: 0.7em;">증빙</span>';
                        headerHtml += `<th>${attrName}${badge}</th>`;
                    }
                }
            } else {
                // 기본 증빙 컬럼
                headerHtml += '<th width="70%">증빙 내용</th>';
            }

            headerHtml += '<th width="15%">결과</th></tr>';
            thead.innerHTML = headerHtml;

            // 표본 #1만 생성
            let rowHtml = '<tr><td class="text-center align-middle">#1</td>';

            if (hasAttributes) {
                // Attribute 컬럼들 추가
                for (let i = 0; i < 10; i++) {
                    const attrName = attributes[`attribute${i}`];
                    if (attrName) {
                        const isPopulation = i < popAttrCount;
                        const bgClass = isPopulation ? 'bg-light' : '';

                        // 설계평가에서는 모든 필드 입력 가능 (표본수 개념 없음)
                        rowHtml += `<td class="align-middle ${bgClass}">
                            <input type="text" class="form-control form-control-sm"
                                   id="design-attr${i}-1"
                                   placeholder="${attrName}"
                                   style="height: 31px;" />
                        </td>`;
                    }
                }
            } else {
                // 기본 증빙 컬럼
                rowHtml += `<td class="align-middle">
                    <input type="text" class="form-control form-control-sm"
                           id="evaluationEvidence"
                           placeholder="평가 시 확인한 증빙 자료를 입력하세요"
                           style="height: 31px;" />
                </td>`;
            }

            // 결과 컬럼
            rowHtml += `<td class="align-middle">
                <select class="form-select form-select-sm"
                        id="overallEffectiveness"
                        required disabled
                        style="height: 31px;">
                    <option value="">선택</option>
                    <option value="effective">효과적</option>
                    <option value="ineffective">비효과적</option>
                </select>
            </td></tr>`;

            tbody.innerHTML = rowHtml;

            console.log('[generateDesignEvidenceTable] Table generated successfully');
        }

        // 기존 평가 데이터 로드 함수
        function loadExistingEvaluationData(sessionName) {
            console.log('Loading evaluation data for session:', sessionName);

            fetch(`/api/design-evaluation/load/{{ rcm_id }}?session=${encodeURIComponent(sessionName)}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.evaluations) {
                        console.log('Loaded evaluations:', data.evaluations.length);

                        // 각 평가 데이터를 폼에 적용
                        data.evaluations.forEach(evaluation => {
                            const controlCode = evaluation.control_code;

                            // 각 필드에 값 설정
                            const adequacySelect = document.querySelector(`select[name="adequacy_${controlCode}"]`);
                            const effectivenessSelect = document.querySelector(`select[name="effectiveness_${controlCode}"]`);
                            const recommendedActions = document.querySelector(`textarea[name="recommended_actions_${controlCode}"]`);

                            if (adequacySelect && evaluation.adequacy_of_description) {
                                adequacySelect.value = evaluation.adequacy_of_description;
                                adequacySelect.dispatchEvent(new Event('change'));
                            }

                            if (effectivenessSelect && evaluation.effectiveness_of_design) {
                                effectivenessSelect.value = evaluation.effectiveness_of_design;
                            }

                            if (recommendedActions && evaluation.recommended_actions) {
                                recommendedActions.value = evaluation.recommended_actions;
                            }
                        });

                        console.log('Evaluation data loaded successfully');
                    } else {
                        console.log('No existing evaluation data found for this session');
                    }
                })
                .catch(error => {
                    console.error('Error loading evaluation data:', error);
                });
        }

        // SessionStorage 디버깅 함수
        function debugSessionStorage() {
            console.log('=== SessionStorage Debug ===');
            console.log('sessionStorage.length:', sessionStorage.length);
            console.log('All sessionStorage items:');
            for (let i = 0; i < sessionStorage.length; i++) {
                const key = sessionStorage.key(i);
                const value = sessionStorage.getItem(key);
                console.log(`  "${key}": "${value}" (type: ${typeof value})`);
            }
            console.log('Direct access:');
            console.log('  currentEvaluationSession:', `"${sessionStorage.getItem('currentEvaluationSession')}"`);
            console.log('  currentEvaluationHeaderId:', `"${sessionStorage.getItem('currentEvaluationHeaderId')}"`);
            console.log('========================');
        }

        // SessionStorage 수동 설정 함수 (디버깅용)
        function setManualSessionStorage() {
            console.log('Setting manual sessionStorage values...');
            sessionStorage.setItem('currentEvaluationSession', 'FY25_설계평가');
            sessionStorage.setItem('currentEvaluationHeaderId', '8');
            console.log('Manual values set. Current sessionStorage:');
            debugSessionStorage();
        }

        // SessionStorage 초기화 함수 (디버깅용)  
        function clearSessionStorage() {
            console.log('Clearing all sessionStorage...');
            sessionStorage.clear();
            console.log('SessionStorage cleared:');
            debugSessionStorage();
        }

        // 이미지 업로드 설정
        function setupImageUpload() {
            const imageInput = document.getElementById('evaluationImages');
            if (imageInput) {
                imageInput.addEventListener('change', handleImageSelection);
            }
        }

        // 이미지 선택 처리
        function handleImageSelection(event) {
            const files = event.target.files;
            const previewContainer = document.getElementById('imagePreview');

            if (!previewContainer) return;

            // 기존 미리보기 초기화
            previewContainer.innerHTML = '';

            // 선택된 이미지가 없으면 종료
            if (!files || files.length === 0) return;

            // 각 파일에 대해 미리보기 생성
            Array.from(files).forEach((file, index) => {
                if (file.type.startsWith('image/')) {
                    const reader = new FileReader();
                    reader.onload = function (e) {
                        const imagePreview = createImagePreview(e.target.result, file.name, index);
                        previewContainer.appendChild(imagePreview);
                    };
                    reader.readAsDataURL(file);
                }
            });

            // 현재 평가의 이미지 저장
            if (currentEvaluationIndex !== null) {
                evaluationImages[currentEvaluationIndex] = Array.from(files);
            }
        }

        // 이미지 미리보기 엘리먼트 생성
        function createImagePreview(src, fileName, index) {
            const div = document.createElement('div');
            div.className = 'image-preview-item d-block mb-3 position-relative';
            div.style.cssText = 'width: 100% !important; max-width: 600px !important;';

            div.innerHTML = `
                <img src="${src}" class="img-thumbnail" style="width: 100% !important; max-width: 600px !important; height: auto !important; display: block !important;" alt="${fileName}">
                <div class="small text-muted mt-1">${fileName}</div>
                <button type="button" class="btn btn-sm btn-danger position-absolute top-0 end-0 rounded-circle"
                        style="width: 20px; height: 20px; padding: 0; margin: 2px;"
                        onclick="removeImagePreview(${index}, this.parentElement)">×</button>
            `;

            return div;
        }

        // 이미지 미리보기 제거
        function removeImagePreview(index, element) {
            element.remove();

            // 파일 입력에서도 제거 (HTML5 FileList는 수정할 수 없으므로 새로운 파일 리스트 생성)
            const imageInput = document.getElementById('evaluationImages');
            if (imageInput && currentEvaluationIndex !== null) {
                const currentFiles = evaluationImages[currentEvaluationIndex] || [];
                const newFiles = currentFiles.filter((_, i) => i !== index);
                evaluationImages[currentEvaluationIndex] = newFiles;

                // 미리보기 컨테이너의 모든 이미지 다시 인덱싱
                updateImageIndices();
            }
        }

        // 이미지 인덱스 업데이트
        function updateImageIndices() {
            const previewContainer = document.getElementById('imagePreview');
            if (!previewContainer) return;

            const imageItems = previewContainer.querySelectorAll('.image-preview-item');
            imageItems.forEach((item, newIndex) => {
                const button = item.querySelector('button');
                if (button) {
                    button.setAttribute('onclick', `removeImagePreview(${newIndex}, this.parentElement)`);
                }
            });
        }

        // 기존 이미지 표시
        function displayExistingImages(images) {
            const previewContainer = document.getElementById('imagePreview');
            if (!previewContainer) return;

            // 기존 미리보기 초기화
            previewContainer.innerHTML = '';

            // 디버깅: 이미지 데이터 확인
            console.log('[displayExistingImages] Images data:', images);

            // 기존 이미지들을 미리보기에 표시
            if (images && images.length > 0) {
                images.forEach((imageInfo, index) => {
                    console.log(`[displayExistingImages] Image ${index}:`, imageInfo);

                    const div = document.createElement('div');
                    div.className = 'image-preview-item d-block mb-3 position-relative';
                    div.style.cssText = 'width: 100% !important; max-width: 600px !important;';

                    // image_id가 있는지 확인
                    if (!imageInfo.image_id) {
                        console.warn(`[displayExistingImages] Image ${index} has no image_id:`, imageInfo);
                    }

                    div.innerHTML = `
                        <img src="${imageInfo.url}" class="img-thumbnail" style="width: 100% !important; max-width: 600px !important; height: auto !important; display: block !important;" alt="${imageInfo.filename}">
                        <div class="small text-muted mt-1">${imageInfo.filename}</div>
                        <div class="small text-success">저장됨</div>
                        <button type="button" class="btn btn-sm btn-danger position-absolute top-0 end-0 rounded-circle"
                                style="width: 20px; height: 20px; padding: 0; margin: 2px;"
                                onclick="deleteExistingImage(${imageInfo.image_id}, this.parentElement)">×</button>
                    `;

                    previewContainer.appendChild(div);
                });
            }
        }

        // 저장된 이미지 삭제
        function deleteExistingImage(imageId, element) {
            if (!confirm('이 이미지를 삭제하시겠습니까?')) {
                return;
            }

            // 버튼 비활성화
            const button = element.querySelector('button');
            if (button) {
                button.disabled = true;
                button.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
            }

            fetch(`/api/design-evaluation/delete-image/${imageId}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // 화면에서 이미지 제거
                        element.remove();

                        // evaluationResults에서도 해당 이미지 제거
                        if (currentEvaluationIndex !== null && evaluationResults[currentEvaluationIndex]) {
                            const images = evaluationResults[currentEvaluationIndex].images || [];
                            evaluationResults[currentEvaluationIndex].images = images.filter(img => img.image_id !== imageId);
                        }

                        showToast('이미지가 삭제되었습니다.', 'success');
                    } else {
                        showToast('삭제 실패: ' + (data.message || '알 수 없는 오류'), 'error');
                        if (button) {
                            button.disabled = false;
                            button.innerHTML = '×';
                        }
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showToast('이미지 삭제 중 오류가 발생했습니다.', 'error');
                    if (button) {
                        button.disabled = false;
                        button.innerHTML = '×';
                    }
                });
        }

        // 평가 이미지 보기 모달
        function showEvaluationImages(index) {
            const evaluation = evaluationResults[index];
            if (!evaluation || !evaluation.images || evaluation.images.length === 0) {
                alert('[DESIGN-001] 첨부된 이미지가 없습니다.');
                return;
            }

            // 이미지 갤러리 모달 생성
            let modalHtml = `
                <div class="modal fade" id="imageGalleryModal" tabindex="-1" aria-hidden="true">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title">평가 첨부 이미지 (${evaluation.images.length}개)</h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                <div class="row">
            `;

            evaluation.images.forEach((imageInfo, imgIndex) => {
                modalHtml += `
                    <div class="col-md-6 mb-3">
                        <div class="card">
                            <img src="${imageInfo.url}" class="card-img-top" style="max-height: 300px; object-fit: contain;" alt="${imageInfo.filename}">
                            <div class="card-body p-2">
                                <small class="text-muted">${imageInfo.filename}</small>
                                <br>
                                <a href="${imageInfo.url}" class="btn btn-sm btn-outline-primary mt-1">
                                    <i class="fas fa-external-link-alt me-1"></i>원본 보기
                                </a>
                            </div>
                        </div>
                    </div>
                `;
            });

            modalHtml += `
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;

            // 기존 모달 제거
            const existingModal = document.getElementById('imageGalleryModal');
            if (existingModal) {
                existingModal.remove();
            }

            // 새 모달 추가 및 표시
            document.body.insertAdjacentHTML('beforeend', modalHtml);
            const modal = new bootstrap.Modal(document.getElementById('imageGalleryModal'));
            modal.show();

            // 모달이 닫히면 DOM에서 제거
            document.getElementById('imageGalleryModal').addEventListener('hidden.bs.modal', function () {
                this.remove();
            });
        }

        // 통제활동 설명 적절성에 따른 효과성 평가 활성화/비활성화
        function setupAdequacyControl() {
            const adequacySelect = document.getElementById('descriptionAdequacy');
            const effectivenessSelect = document.getElementById('overallEffectiveness');
            const effectivenessSection = document.getElementById('effectivenessSection');
            const recommendedActionsField = document.getElementById('recommendedActions');

            if (adequacySelect && effectivenessSelect) {
                // 초기 상태 설정
                toggleEffectivenessSection(adequacySelect.value);

                // 이벤트 리스너 추가
                adequacySelect.addEventListener('change', function () {
                    toggleEffectivenessSection(this.value);
                });
            }

            function toggleEffectivenessSection(adequacyValue) {
                const evaluationEvidence = document.getElementById('evaluationEvidence');
                if (adequacyValue === 'adequate') {
                    // 적절함인 경우 효과성 필드 활성화
                    effectivenessSelect.disabled = false;
                    effectivenessSection.style.opacity = '1';

                    // 증빙 내용이 비어있으면 기본 텍스트 입력
                    if (evaluationEvidence && !evaluationEvidence.value.trim()) {
                        evaluationEvidence.value = '통제 활동 수행 기록, 관련 문서 및 증적 확인';
                    }
                } else {
                    // 적절함이 아닌 경우 효과성 필드 비활성화 및 초기화
                    effectivenessSelect.disabled = true;
                    effectivenessSelect.value = '';
                    recommendedActionsField.value = '';
                    recommendedActionsField.disabled = true;
                    effectivenessSection.style.opacity = '0.5';

                    // 증빙 내용이 비어있으면 기본 텍스트 입력
                    if (evaluationEvidence && !evaluationEvidence.value.trim()) {
                        evaluationEvidence.value = '통제 활동 설명 문서 및 관련 자료 검토';
                    }
                }
            }
        }

        // 권고 조치사항 필드 조건부 활성화 설정
        function setupRecommendedActionsField() {
            const effectivenessSelect = document.getElementById('overallEffectiveness');
            const recommendedActionsField = document.getElementById('recommendedActions');

            if (effectivenessSelect && recommendedActionsField) {
                // 초기 상태 설정
                toggleRecommendedActions(effectivenessSelect.value);

                // 이벤트 리스너 추가
                effectivenessSelect.addEventListener('change', function () {
                    toggleRecommendedActions(this.value);
                });
            }
        }

        // 해당 없음 (통제 미시행) 체크 시 필드 토글 (설계평가)
        function toggleNoOccurrenceDesign() {
            const noOccurrenceCheckbox = document.getElementById('no_occurrence_design');
            const designEvidenceSection = document.getElementById('design-evidence-section');
            const noOccurrenceReasonSection = document.getElementById('no-occurrence-reason-section-design');
            const recommendedActionsSection = document.getElementById('recommended-actions-section');
            const designCommentSection = document.getElementById('design-comment-section');
            const evaluationImagesSection = document.getElementById('evaluation-images-section');

            console.log('[toggleNoOccurrenceDesign] 호출됨');
            console.log('[toggleNoOccurrenceDesign] 체크박스 상태:', noOccurrenceCheckbox?.checked);
            console.log('[toggleNoOccurrenceDesign] 찾은 요소들:', {
                designEvidenceSection: !!designEvidenceSection,
                recommendedActionsSection: !!recommendedActionsSection,
                designCommentSection: !!designCommentSection,
                evaluationImagesSection: !!evaluationImagesSection
            });

            if (noOccurrenceCheckbox && noOccurrenceCheckbox.checked) {
                console.log('[toggleNoOccurrenceDesign] 섹션 숨기기 시작');
                // 증빙 섹션 숨기기
                if (designEvidenceSection) {
                    designEvidenceSection.style.display = 'none';
                    console.log('[toggleNoOccurrenceDesign] 증빙 섹션 숨김');
                }

                // 권고 조치사항, 설계 평가 코멘트, 이미지 업로드 섹션 숨기기
                if (recommendedActionsSection) {
                    recommendedActionsSection.style.display = 'none';
                    console.log('[toggleNoOccurrenceDesign] 권고 조치사항 숨김');
                }
                if (designCommentSection) {
                    designCommentSection.style.display = 'none';
                    console.log('[toggleNoOccurrenceDesign] 설계 평가 코멘트 숨김');
                }
                if (evaluationImagesSection) {
                    evaluationImagesSection.style.display = 'none';
                    console.log('[toggleNoOccurrenceDesign] 이미지 업로드 숨김');
                }

                // 사유 입력란 표시
                if (noOccurrenceReasonSection) {
                    noOccurrenceReasonSection.style.display = 'block';
                    console.log('[toggleNoOccurrenceDesign] 사유 입력란 표시');
                }
            } else {
                console.log('[toggleNoOccurrenceDesign] 섹션 표시 시작');
                // 증빙 섹션 표시
                if (designEvidenceSection) {
                    designEvidenceSection.style.display = 'block';
                }

                // 권고 조치사항, 설계 평가 코멘트, 이미지 업로드 섹션 표시
                if (recommendedActionsSection) {
                    recommendedActionsSection.style.display = 'block';
                }
                if (designCommentSection) {
                    designCommentSection.style.display = 'block';
                }
                if (evaluationImagesSection) {
                    evaluationImagesSection.style.display = 'block';
                }

                // 사유 입력란 숨김
                if (noOccurrenceReasonSection) {
                    noOccurrenceReasonSection.style.display = 'none';
                }
            }
        }

        // 권고 조치사항 필드 활성화/비활성화
        function toggleRecommendedActions(effectivenessValue) {
            console.log('[toggleRecommendedActions] 호출됨, effectivenessValue:', effectivenessValue);
            const recommendedActionsField = document.getElementById('recommendedActions');
            const evaluationEvidence = document.getElementById('evaluationEvidence');
            const container = recommendedActionsField.closest('.mb-3');

            // 해당 없음이 체크되어 있으면 권고 조치사항을 표시하지 않음
            const noOccurrenceCheckbox = document.getElementById('no_occurrence_design');
            console.log('[toggleRecommendedActions] 해당 없음 체크 상태:', noOccurrenceCheckbox?.checked);
            if (noOccurrenceCheckbox && noOccurrenceCheckbox.checked) {
                console.log('[toggleRecommendedActions] 해당 없음이 체크되어 있어서 권고 조치사항 숨김');
                if (container) {
                    container.style.display = 'none';
                }
                return;
            }

            if (effectivenessValue === 'effective') {
                // 효과적인 경우 완전히 숨김
                recommendedActionsField.value = '';
                if (container) {
                    container.style.display = 'none';
                }

                // 증빙 내용이 비어있으면 효과적 평가 텍스트 입력 (evaluationEvidence가 있는 경우만)
                if (evaluationEvidence && !evaluationEvidence.value.trim()) {
                    evaluationEvidence.value = '통제 설계 및 운영 증적, 수행 결과 확인';
                }
            } else if (effectivenessValue === 'partially_effective') {
                // 부분적으로 효과적인 경우
                recommendedActionsField.disabled = false;
                recommendedActionsField.placeholder = '실무와 문서 간 차이 해소나 통제 운영 개선을 위한 구체적인 조치사항을 제안하세요...';
                if (container) {
                    container.style.display = 'block';
                }

                // 증빙 내용이 비어있으면 부분 효과적 평가 텍스트 입력 (evaluationEvidence가 있는 경우만)
                if (evaluationEvidence && !evaluationEvidence.value.trim()) {
                    evaluationEvidence.value = '통제 활동 기록 및 일부 개선 필요 사항 확인';
                }
            } else if (effectivenessValue === 'ineffective') {
                // 비효과적인 경우
                recommendedActionsField.disabled = false;
                recommendedActionsField.placeholder = '실무와 문서 간 차이 해소나 통제 운영 개선을 위한 구체적인 조치사항을 제안하세요...';
                if (container) {
                    container.style.display = 'block';
                }

                // 증빙 내용이 비어있으면 비효과적 평가 텍스트 입력 (evaluationEvidence가 있는 경우만)
                if (evaluationEvidence && !evaluationEvidence.value.trim()) {
                    evaluationEvidence.value = '통제 활동 미흡 사항 및 개선 필요 증적 확인';
                }
            } else {
                // 선택되지 않은 경우
                if (container) {
                    container.style.display = 'none';
                }
            }
        }

        // 개선 제안사항 필드 조건부 활성화 설정
        function setupImprovementSuggestionField() {
            const adequacySelect = document.getElementById('descriptionAdequacy');
            const improvementField = document.getElementById('improvementSuggestion');

            if (adequacySelect && improvementField) {
                // 초기 상태 설정
                toggleImprovementSuggestion(adequacySelect.value);

                // 이벤트 리스너 추가
                adequacySelect.addEventListener('change', function () {
                    toggleImprovementSuggestion(this.value);
                });
            }
        }

        // 개선 제안사항 필드 활성화/비활성화
        function toggleImprovementSuggestion(adequacyValue) {
            const improvementField = document.getElementById('improvementSuggestion');
            const container = improvementField.closest('.mb-3');

            if (adequacyValue === 'adequate') {
                // 적절한 경우 비활성화
                improvementField.disabled = true;
                improvementField.value = '';
                improvementField.placeholder = '현실 반영도가 적절하므로 개선사항이 필요하지 않습니다.';
                if (container) { // '적절함'일 경우 숨김
                    container.style.display = 'none';
                }
            } else {
                // 부분적으로 적절, 부적절, 누락인 경우 활성화
                improvementField.disabled = false;
                improvementField.placeholder = '실제 업무와 차이가 있는 경우, RCM 문서 업데이트 방향이나 실무 개선 방안을 제안하세요...';
                if (container) { // 그 외의 경우 표시
                    container.style.display = 'block';
                }
            }
        }

        // 성공 메시지 표시 함수
        function showSuccessMessage(message) {
            const alertHtml = `
                <div class="alert alert-success alert-dismissible fade show position-fixed"
                     style="top: 20px; right: 20px; z-index: 9999; min-width: 300px;"
                     role="alert" id="successAlert">
                    <i class="fas fa-check-circle me-2"></i>
                    <strong>${message}</strong>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            `;

            // 기존 성공 알림 제거
            const existingAlert = document.getElementById('successAlert');
            if (existingAlert) {
                existingAlert.remove();
            }

            // 새 알림 추가
            document.body.insertAdjacentHTML('beforeend', alertHtml);

            // 3초 후 자동으로 알림 제거
            setTimeout(() => {
                const alert = document.getElementById('successAlert');
                if (alert) {
                    alert.remove();
                }
            }, 3000);
        }

        // Toast 알림 함수 (success, error, warning, info 타입 지원)
        function showToast(message, type = 'success') {
            const typeConfig = {
                success: { class: 'alert-success', icon: 'fa-check-circle' },
                error: { class: 'alert-danger', icon: 'fa-exclamation-circle' },
                warning: { class: 'alert-warning', icon: 'fa-exclamation-triangle' },
                info: { class: 'alert-info', icon: 'fa-info-circle' }
            };

            const config = typeConfig[type] || typeConfig.success;
            const toastId = 'toast-' + Date.now();

            const alertHtml = `
                <div class="alert ${config.class} alert-dismissible fade show position-fixed"
                     style="top: 20px; right: 20px; z-index: 9999; min-width: 300px;"
                     role="alert" id="${toastId}">
                    <i class="fas ${config.icon} me-2"></i>
                    <strong>${message}</strong>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            `;

            // 새 알림 추가
            document.body.insertAdjacentHTML('beforeend', alertHtml);

            // 3초 후 자동으로 알림 제거
            setTimeout(() => {
                const toast = document.getElementById(toastId);
                if (toast) {
                    toast.remove();
                }
            }, 3000);
        }

        // 전역으로 함수 노출 (브라우저 콘솔에서 호출 가능)
        window.debugSessionStorage = debugSessionStorage;
        window.setManualSessionStorage = setManualSessionStorage;
        window.clearSessionStorage = clearSessionStorage;

        // 설계평가 다운로드 함수
        function downloadDesignEvaluation() {
            const currentSession = sessionStorage.getItem('currentEvaluationSession');

            if (!currentSession) {
                alert('[DOWNLOAD-001] 평가 세션 정보를 찾을 수 없습니다.');
                return;
            }

            const rcmId = {{ rcm_id }};
        const evaluationSession = encodeURIComponent(currentSession);

        // 다운로드 URL 생성 (더 강력한 이미지 처리가 포함된 API 사용)
        const downloadUrl = `/api/design-evaluation/download-excel/${rcmId}?evaluation_session=${evaluationSession}`;

        // 다운로드 실행
        window.location.href = downloadUrl;
        }

        // 다운로드 버튼 설정 (표시 여부만 제어)
        function setupDownloadButton() {
            // 다운로드 버튼은 완료된 평가에서만 표시됨
            // updateProgress() 함수에서 제어
        }

        // 페이지 로드 시 기존 평가 결과 불러오기
        document.addEventListener('DOMContentLoaded', function () {
            // SessionStorage 상태 확인
            debugSessionStorage();

            // 서버에서 전달받은 evaluation_session이 있으면 사용
            {% if evaluation_session %}
            const serverSession = '{{ evaluation_session }}';
            console.log('Server provided session:', serverSession);
            sessionStorage.setItem('currentEvaluationSession', serverSession);
            sessionStorage.setItem('isNewEvaluationSession', 'false'); // 기존 세션
            {% endif %}

            // 새 세션인지 확인
            const isNewSession = sessionStorage.getItem('isNewEvaluationSession') === 'true';
            const currentSession = sessionStorage.getItem('currentEvaluationSession');

            console.log('Page loaded - Current session:', currentSession);
            console.log('Is new session:', isNewSession);

            if (!currentSession) {
                // 세션 정보가 없으면 기본 세션명 설정
                const defaultSession = `평가_${new Date().getTime()}`;
                sessionStorage.setItem('currentEvaluationSession', defaultSession);
                console.log('No session found, created default session:', defaultSession);

                // 새 세션이므로 평가 구조 생성
                createEvaluationStructure(defaultSession);
            }

            // 평가명 화면에 표시
            updateEvaluationNameDisplay();

            // 다운로드 버튼 이벤트 설정
            setupDownloadButton();

            // 통제활동 설명 적절성에 따른 효과성 평가 활성화/비활성화 설정
            setupAdequacyControl();

            // 권고 조치사항 필드 조건부 활성화 설정
            setupRecommendedActionsField();

            // 개선 제안사항 필드 조건부 활성화 설정
            setupImprovementSuggestionField();

            if (isNewSession && currentSession) {
                // 새 세션 알림 표시
                showNewSessionAlert(currentSession);
                // 플래그 제거 (다시 새로고침해도 메시지 안 나오도록)
                sessionStorage.removeItem('isNewEvaluationSession');
            }

            // 기존 평가 데이터 로드 (모든 경우에 실행)
            loadExistingEvaluations();
        });

        // 평가명 화면에 표시
        function updateEvaluationNameDisplay() {
            const currentSession = sessionStorage.getItem('currentEvaluationSession');
            if (currentSession) {
                document.getElementById('currentEvaluationName').textContent = currentSession;
                document.getElementById('evaluationNameDisplay').style.display = 'block';
            } else {
                document.getElementById('evaluationNameDisplay').style.display = 'none';
            }
        }

        // 평가 구조 생성
        function createEvaluationStructure(sessionName) {
            console.log('Creating evaluation structure for session:', sessionName);

            fetch('/api/design-evaluation/create-evaluation', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    rcm_id: rcmId,
                    evaluation_session: sessionName
                })
            })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        console.log('Evaluation structure created successfully');
                        // 새 평가 생성 시 이전 완료 상태 정리
                        sessionStorage.removeItem('headerCompletedDate');
                        console.log('Cleared previous headerCompletedDate for new evaluation');
                    } else {
                        console.error('Failed to create evaluation structure:', data.message);
                    }
                })
                .catch(error => {
                    console.error('Error creating evaluation structure:', error);
                });
        }

        // 새 세션 알림 표시
        function showNewSessionAlert(sessionName) {
            const alertHtml = `
                <div class="alert alert-success alert-dismissible fade show" role="alert" id="newSessionAlert">
                    <i class="fas fa-check-circle me-2"></i>
                    <strong>새로운 설계평가가 생성되었습니다!</strong>
                    <br>평가 세션명: <strong>"${sessionName}"</strong>
                    <br>모든 통제에 대한 평가 틀이 준비되었습니다. 각 통제별로 평가를 수행하고 저장하세요.
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            `;

            // RCM 기본 정보 카드 다음에 알림 삽입
            const rcmInfoCard = document.querySelector('.card.border-success');
            if (rcmInfoCard && rcmInfoCard.parentNode) {
                rcmInfoCard.insertAdjacentHTML('afterend', alertHtml);

                // 10초 후 자동으로 알림 제거
                setTimeout(() => {
                    const alert = document.getElementById('newSessionAlert');
                    if (alert) {
                        alert.remove();
                    }
                }, 10000);
            }
        }

        // 기존 평가 결과 불러오기
        function loadExistingEvaluations() {
            const currentSession = sessionStorage.getItem('currentEvaluationSession');
            const headerId = sessionStorage.getItem('currentEvaluationHeaderId');

            console.log('DEBUG - SessionStorage values:');
            console.log('currentEvaluationSession:', currentSession);
            console.log('currentEvaluationHeaderId:', headerId);
            console.log('headerId type:', typeof headerId);
            console.log('headerId is null:', headerId === null);
            console.log('headerId is undefined:', headerId === undefined);

            // 항상 세션명으로 로드하여 최신 header_id를 사용
            let url;
            if (currentSession) {
                url = `/api/design-evaluation/load/${rcmId}?session=${encodeURIComponent(currentSession)}`;
                console.log('Using session route to get latest header_id');
            } else {
                url = `/api/design-evaluation/load/${rcmId}`;
                console.log('Using default route');
            }

            console.log('Loading evaluations from URL:', url);

            fetch(url)
                .then(response => response.json())
                .then(data => {
                    console.log('API Response received:', {
                        success: data.success,
                        evaluations_count: Object.keys(data.evaluations || {}).length,
                        header_id: data.header_id,
                        header_completed_date: data.header_completed_date
                    });

                    if (data.success && data.evaluations) {
                        // 응답에서 header_id와 completed_date를 받으면 sessionStorage에 저장
                        if (data.header_id) {
                            sessionStorage.setItem('currentEvaluationHeaderId', data.header_id);
                        }

                        // header의 completed_date 저장 및 정리
                        if (data.header_completed_date && data.header_completed_date !== 'null' && data.header_completed_date !== null) {
                            sessionStorage.setItem('headerCompletedDate', data.header_completed_date);
                        } else {
                            sessionStorage.removeItem('headerCompletedDate');
                        }

                        // 컨트롤 코드를 인덱스로 매핑
                        let matchedCount = 0;
                        let notMatchedCodes = [];
                        let matchedList = [];
                        {% for detail in rcm_details %}
                        const controlCode{{ loop.index }} = '{{ detail.control_code }}';
                        if (data.evaluations[controlCode{{ loop.index }}]) {
                            const evaluationData = data.evaluations[controlCode{{ loop.index }}];
                            matchedList.push({
                                index: {{ loop.index }},
                                code: controlCode{{ loop.index }},
                                evaluation_date: evaluationData.evaluation_date,
                                adequacy: evaluationData.description_adequacy,
                                effectiveness: evaluationData.overall_effectiveness
                            });

                            evaluationResults[{{ loop.index }}] = evaluationData;
                            updateEvaluationUI({{ loop.index }}, evaluationData);
                            matchedCount++;
                        } else {
                            notMatchedCodes.push({ index: {{ loop.index }}, code: controlCode{{ loop.index }} });
                        }
                        {% endfor %}

                        console.log(`Matching completed: ${matchedCount} / {{ rcm_details|length }}`, {
                            matched_count: matchedCount,
                            total_count: {{ rcm_details|length }},
                            matched_samples: matchedList.slice(0, 3),
                            not_matched_count: notMatchedCodes.length,
                            not_matched_samples: notMatchedCodes.slice(0, 3)
                        });

                                updateProgress();
                    }
                })
                .catch (error => {
            console.error('기존 평가 결과 불러오기 오류:', error);
        });

        // 이미지 업로드 처리
        setupImageUpload();
        }

        // 평가 모달 열기
        function openEvaluationModal(index, controlCode, controlName) {
            console.log('=== openEvaluationModal called ===');
            console.log('Parameters:', { index, controlCode, controlName });

            // 헤더 완료 상태 확인 (더 엄격한 체크)
            const headerCompletedDate = sessionStorage.getItem('headerCompletedDate');
            const isHeaderCompleted = headerCompletedDate &&
                headerCompletedDate !== 'null' &&
                headerCompletedDate !== null &&
                headerCompletedDate !== 'undefined' &&
                headerCompletedDate.trim() !== '' &&
                headerCompletedDate.trim() !== 'null';

            console.log('Modal open check - headerCompletedDate:', `'${headerCompletedDate}'`, 'isHeaderCompleted:', isHeaderCompleted);

            if (isHeaderCompleted) {
                // 완료된 상태에서는 조회만 가능하도록 처리 (alert 제거)
                console.log('Header completed, opening in view-only mode');
            }

            currentEvaluationIndex = index;

            // 해당 행의 데이터 가져오기
            const row = document.getElementById(`control-row-${index}`);
            const cells = row.querySelectorAll('td');

            // 모달에 기본 정보 설정
            document.getElementById('modalControlCode').textContent = controlCode;
            document.getElementById('modalControlName').textContent = controlName;

            // 통제 세부 정보 설정
            const description = cells[2].textContent.trim();
            const frequency = cells[3].textContent.trim();
            const type = cells[4].textContent.trim();

            document.getElementById('modalControlDescription').textContent = description || '통제활동 설명이 등록되지 않았습니다.';
            document.getElementById('modalControlFrequency').textContent = frequency || '-';
            document.getElementById('modalControlType').textContent = type || '-';

            // RCM 세부 데이터에서 통제성격(Nature) 찾기
            {% for detail in rcm_details %}
            if ({{ loop.index }} === index) {
                document.getElementById('modalControlNature').textContent = '{{ detail.control_nature_name or detail.control_nature or "-" }}';
            }
            {% endfor %}
            
                    // Attribute 기반 증빙 테이블 생성 (기존 데이터 로드 전에 먼저 생성)
        generateDesignEvidenceTable(controlCode);

        // 동적으로 생성된 요소에 이벤트 리스너 재설정
        setupAdequacyControl();
        setupRecommendedActionsField();

        // 기본 디버깅
        console.log('DEBUG - Modal opened for index:', index);
        console.log('DEBUG - evaluationResults:', evaluationResults);
        console.log('DEBUG - evaluationResults[index]:', evaluationResults[index]);

        // 기존 평가 결과가 있다면 로드
        if (evaluationResults[index]) {
            const result = evaluationResults[index];
            console.log('DEBUG - Full result data:', result);

            document.getElementById('descriptionAdequacy').value = result.description_adequacy || '';
            document.getElementById('improvementSuggestion').value = result.improvement_suggestion || '';
            document.getElementById('overallEffectiveness').value = result.overall_effectiveness || '';

            // Attribute 데이터 로드 (evaluation_evidence는 항상 JSON 형식)
            if (result.evaluation_evidence) {
                try {
                    const attrData = JSON.parse(result.evaluation_evidence);

                    const evidenceEl = document.getElementById('evaluationEvidence');
                    if (evidenceEl) {
                        // 기본 증빙 필드 - attribute0에서 로드
                        evidenceEl.value = attrData['attribute0'] || '';
                    } else {
                        // Attribute 기반인 경우 - 각 attribute 필드에 입력
                        for (let i = 0; i < 10; i++) {
                            const attrEl = document.getElementById(`design-attr${i}-1`);
                            if (attrEl && attrData[`attribute${i}`]) {
                                attrEl.value = attrData[`attribute${i}`];
                            }
                        }
                    }
                } catch (e) {
                    console.log('[openEvaluationModal] evaluation_evidence is not JSON:', result.evaluation_evidence);
                    // JSON 파싱 실패 시 레거시 데이터 처리 (일반 텍스트)
                    const evidenceEl = document.getElementById('evaluationEvidence');
                    if (evidenceEl) {
                        evidenceEl.value = result.evaluation_evidence || '';
                    }
                }
            }

            document.getElementById('designComment').value = result.design_comment || '';
            document.getElementById('recommendedActions').value = result.recommended_actions || '';

            // 당기 발생사실 없음 데이터 로드
            if (result.no_occurrence) {
                const noOccurrenceCheckbox = document.getElementById('no_occurrence_design');
                const noOccurrenceReason = document.getElementById('no_occurrence_reason_design');
                if (noOccurrenceCheckbox) {
                    noOccurrenceCheckbox.checked = true;
                    if (noOccurrenceReason && result.no_occurrence_reason) {
                        noOccurrenceReason.value = result.no_occurrence_reason;
                    }
                    toggleNoOccurrenceDesign();
                }
            }

            // 적절성 값이 설정되면 효과성 필드 활성화 이벤트 발생
            const adequacySelect = document.getElementById('descriptionAdequacy');
            if (adequacySelect.value === 'adequate') {
                // 효과성 필드 활성화 후, 결론 값에 따라 권고 조치사항 필드 표시 여부 업데이트
                const effectivenessSelect = document.getElementById('overallEffectiveness');
                if (effectivenessSelect) {
                    toggleRecommendedActions(effectivenessSelect.value);
                }
                adequacySelect.dispatchEvent(new Event('change'));
            }

            // 기존 이미지 표시
            console.log('DEBUG - Images data:', result.images);
            displayExistingImages(result.images || []);
        } else {
            // 폼 초기화
            document.getElementById('descriptionAdequacy').value = '';
            document.getElementById('improvementSuggestion').value = '';
            document.getElementById('overallEffectiveness').value = '';

            // evaluationEvidence가 있으면 초기화 (기본 증빙 컬럼)
            const evidenceElInit = document.getElementById('evaluationEvidence');
            if (evidenceElInit) {
                evidenceElInit.value = '';
            } else {
                // Attribute 기반인 경우 모든 attribute 필드 초기화
                for (let i = 0; i < 10; i++) {
                    const attrEl = document.getElementById(`design-attr${i}-1`);
                    if (attrEl) attrEl.value = '';
                }
            }

            document.getElementById('designComment').value = '';
            document.getElementById('recommendedActions').value = '';

            // 당기 발생사실 없음 초기화
            const noOccurrenceCheckbox = document.getElementById('no_occurrence_design');
            const noOccurrenceReason = document.getElementById('no_occurrence_reason_design');
            if (noOccurrenceCheckbox) noOccurrenceCheckbox.checked = false;
            if (noOccurrenceReason) noOccurrenceReason.value = '';
            toggleNoOccurrenceDesign();

            // 폼 초기화 시 권고 조치사항 필드 숨김
            toggleRecommendedActions('');

            // 이미지 초기화
            displayExistingImages([]);
        }

        // 이미지 입력 필드 초기화
        const imageInput = document.getElementById('evaluationImages');
        if (imageInput) imageInput.value = '';

        // 완료 상태 확인하여 저장 버튼 및 파일 업로드 제어
        const saveButton = document.getElementById('saveEvaluationBtn');
        const cancelButton = document.querySelector('#evaluationModal .modal-footer .btn-outline-secondary');
        const imageUploadSection = document.getElementById('imageUploadSection');

        if (saveButton) {
            if (isHeaderCompleted) {
                saveButton.disabled = true;
                saveButton.innerHTML = '<i class="fas fa-lock me-1"></i>완료된 평가';
                saveButton.title = '평가가 완료되어 수정할 수 없습니다';
                saveButton.classList.remove('btn-success');
                saveButton.classList.add('btn-secondary');
            } else {
                saveButton.disabled = false;
                saveButton.innerHTML = '<i class="fas fa-save me-1"></i>평가 저장';
                saveButton.title = '평가 결과를 저장합니다';
                saveButton.classList.remove('btn-secondary');
                saveButton.classList.add('btn-success');
            }
        }

        // 완료 상태일 때 파일 업로드 섹션 숨김
        if (imageUploadSection) {
            if (isHeaderCompleted) {
                imageUploadSection.style.display = 'none';
            } else {
                imageUploadSection.style.display = 'block';
            }
        }

        // 닫기 버튼은 항상 "닫기"로 표시 (이미 HTML에 설정됨)

        // 이미지 업로드 버튼 및 입력 필드 제어
        const uploadImageBtn = document.querySelector('#evaluationModal button[onclick*="uploadImageModal"]');

        if (isHeaderCompleted) {
            // 완료된 상태: 이미지 업로드 비활성화
            if (uploadImageBtn) {
                uploadImageBtn.disabled = true;
                uploadImageBtn.classList.add('disabled');
                uploadImageBtn.style.cursor = 'not-allowed';
            }
            if (imageInput) {
                imageInput.disabled = true;
            }

            // 모든 입력 필드 비활성화
            document.getElementById('descriptionAdequacy').disabled = true;
            document.getElementById('improvementSuggestion').disabled = true;
            document.getElementById('overallEffectiveness').disabled = true;

            // evaluationEvidence가 있으면 비활성화 (기본 증빙 컬럼)
            const evidenceEl = document.getElementById('evaluationEvidence');
            if (evidenceEl) {
                evidenceEl.disabled = true;
            } else {
                // Attribute 기반인 경우 모든 attribute 필드 비활성화
                for (let i = 0; i < 10; i++) {
                    const attrEl = document.getElementById(`design-attr${i}-1`);
                    if (attrEl) attrEl.disabled = true;
                }
            }

            document.getElementById('designComment').disabled = true;
            document.getElementById('recommendedActions').disabled = true;
        } else {
            // 완료되지 않은 상태: 모든 입력 활성화
            if (uploadImageBtn) {
                uploadImageBtn.disabled = false;
                uploadImageBtn.classList.remove('disabled');
                uploadImageBtn.style.cursor = 'pointer';
            }
            if (imageInput) {
                imageInput.disabled = false;
            }

            // 모든 입력 필드 활성화
            document.getElementById('descriptionAdequacy').disabled = false;
            document.getElementById('improvementSuggestion').disabled = false;
            document.getElementById('overallEffectiveness').disabled = false;

            // evaluationEvidence가 있으면 활성화 (기본 증빙 컬럼)
            const evidenceElActive = document.getElementById('evaluationEvidence');
            if (evidenceElActive) {
                evidenceElActive.disabled = false;
            } else {
                // Attribute 기반인 경우 모든 attribute 필드 활성화
                for (let i = 0; i < 10; i++) {
                    const attrEl = document.getElementById(`design-attr${i}-1`);
                    if (attrEl) attrEl.disabled = false;
                }
            }

            document.getElementById('designComment').disabled = false;
            document.getElementById('recommendedActions').disabled = false;
        }

        // 표준 표본수가 0인 경우 "당기 발생사실 없음" 체크박스 표시
        {% for detail in rcm_details %}
        if ({{ loop.index }} === index) {
            // 자동통제 판별
            const controlNature = '{{ detail.control_nature or "" }}';
            const isAutomated = controlNature && (
                controlNature.toUpperCase() === 'A' ||
                controlNature.includes('자동') ||
                controlNature.toLowerCase().includes('auto') ||
                controlNature.toLowerCase().includes('automated')
            );

            // 자동통제가 아닐 때만 당기 발생사실 없음 옵션 표시
            const noOccurrenceSection = document.getElementById('no-occurrence-section-design');
            if (noOccurrenceSection) {
                if (isAutomated) {
                    noOccurrenceSection.style.display = 'none';
                    // 자동통제의 경우 체크 해제
                    const noOccurrenceCheckbox = document.getElementById('no_occurrence_design');
                    if (noOccurrenceCheckbox) noOccurrenceCheckbox.checked = false;
                } else {
                    noOccurrenceSection.style.display = 'block';
                }
            }
        }
        {% endfor %}

        const modal = new bootstrap.Modal(document.getElementById('evaluationModal'));
        modal.show();

        // 모달이 완전히 표시된 후 해당 없음 체크박스 상태에 따라 섹션 표시/숨김 적용
        setTimeout(() => {
            toggleNoOccurrenceDesign();
        }, 100);
        }

        // 평가 결과 저장
        function saveEvaluation() {
            console.log('saveEvaluation function called');

            // 완료 상태 확인 - 완료된 평가는 저장할 수 없음
            const headerCompletedDate = sessionStorage.getItem('headerCompletedDate');
            const isHeaderCompleted = headerCompletedDate &&
                headerCompletedDate !== 'null' &&
                headerCompletedDate !== null &&
                headerCompletedDate !== 'undefined' &&
                headerCompletedDate.trim() !== '' &&
                headerCompletedDate.trim() !== 'null';

            if (isHeaderCompleted) {
                console.log('Header completed, save blocked');
                return; // alert 없이 조용히 함수 종료
            }

            const currentSession = sessionStorage.getItem('currentEvaluationSession');
            console.log('Current evaluation session from storage:', currentSession);

            if (!currentSession) {
                alert('[DESIGN-003] 평가 세션 정보를 찾을 수 없습니다. 설계평가 목록에서 다시 시작해주세요.');
                return;
            }

            // 해당 없음 (통제 미시행) 데이터 수집
            const noOccurrenceCheckbox = document.getElementById('no_occurrence_design');
            const noOccurrenceReason = document.getElementById('no_occurrence_reason_design');
            const noOccurrence = noOccurrenceCheckbox ? noOccurrenceCheckbox.checked : false;
            const noOccurrenceReasonText = noOccurrenceReason ? noOccurrenceReason.value : '';

            // 해당 없음이 체크된 경우 사유만 필수 검증
            if (noOccurrence) {
                if (!noOccurrenceReasonText || noOccurrenceReasonText.trim() === '') {
                    alert('통제 미시행 사유를 입력해주세요.');
                    return;
                }
            } else {
                // 해당 없음이 아닌 경우에만 일반 검증 수행
                const adequacy = document.getElementById('descriptionAdequacy').value;
                const effectiveness = document.getElementById('overallEffectiveness').value;

                console.log('Form validation - adequacy:', adequacy, 'effectiveness:', effectiveness);

                if (!adequacy) {
                    alert('[DESIGN-004] 통제활동 설명 적절성 평가는 필수 항목입니다.');
                    return;
                }

                // 적절함인 경우에만 효과성 평가 필수
                if (adequacy === 'adequate' && !effectiveness) {
                    alert('[DESIGN-005] 종합 설계 효과성 평가는 필수 항목입니다.');
                    return;
                }
            }

            const adequacy = document.getElementById('descriptionAdequacy').value;
            const effectiveness = document.getElementById('overallEffectiveness').value;

            // 증빙 데이터 수집 (항상 JSON 형식으로 저장)
            let evidenceData = '';
            const evidenceEl = document.getElementById('evaluationEvidence');

            const attrData = {};
            if (evidenceEl) {
                // 기본 증빙 필드 - attribute0에 저장
                attrData['attribute0'] = evidenceEl.value;
            } else {
                // Attribute 기반 - 모든 attribute 필드 값을 수집
                for (let i = 0; i < 10; i++) {
                    const attrEl = document.getElementById(`design-attr${i}-1`);
                    if (attrEl) {
                        attrData[`attribute${i}`] = attrEl.value;
                    }
                }
            }
            evidenceData = JSON.stringify(attrData);

            const evaluation = {
                description_adequacy: adequacy,
                improvement_suggestion: document.getElementById('improvementSuggestion').value,
                overall_effectiveness: effectiveness,
                evaluation_evidence: evidenceData,
                design_comment: document.getElementById('designComment').value,
                recommended_actions: document.getElementById('recommendedActions').value,
                no_occurrence: noOccurrence,
                no_occurrence_reason: noOccurrenceReasonText
            };

            // 서버에 결과 저장
            const controlCode = {% for detail in rcm_details %}
        {{ loop.index }} === currentEvaluationIndex ? '{{ detail.control_code }}' :
            {% endfor %} null;

        console.log('Control code:', controlCode);

        if (!controlCode) {
            alert('[DESIGN-006] 통제 코드를 찾을 수 없습니다. 다시 시도해주세요.');
            return;
        }

        // 저장 버튼 비활성화 (중복 저장 방지)
        const saveButton = document.getElementById('saveEvaluationBtn') ||
            document.querySelector('#evaluationModal .btn-success') ||
            document.querySelector('#evaluationModal .btn-primary') ||
            document.querySelector('#evaluationModal button[onclick="saveEvaluation()"]');

        console.log('Save button found:', saveButton);

        if (!saveButton) {
            console.error('Save button not found!');
            alert('[DESIGN-007] 저장 버튼을 찾을 수 없습니다.');
            return;
        }

        // 이미지 데이터 준비
        const imageData = evaluationImages[currentEvaluationIndex] || [];

        // 기존에 저장된 이미지 개수 확인
        const existingImages = (evaluationResults[currentEvaluationIndex]?.images || []).length;
        const totalImageCount = imageData.length + existingImages;

        // 증빙자료 업로드 확인 (해당 없음이 아니고, 적정이면서 효과적인 경우에만)
        if (!noOccurrence && adequacy === 'adequate' && effectiveness === 'effective' && totalImageCount === 0) {
            const confirmed = confirm('평가 결과가 "적정" 및 "효과적"이지만 업로드된 증빙자료가 없습니다.\n\n증빙자료 없이 평가를 저장하시겠습니까?');
            if (!confirmed) {
                console.log('User cancelled save due to no evidence files');
                return; // 사용자가 취소를 선택한 경우 저장 중단
            }
        }

        const originalText = saveButton.innerHTML;
        saveButton.disabled = true;
        saveButton.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>저장 중...';

        // FormData를 사용하여 이미지 파일과 함께 전송
        const formData = new FormData();
        formData.append('rcm_id', rcmId);
        formData.append('control_code', controlCode);
        formData.append('evaluation_data', JSON.stringify(evaluation));
        formData.append('evaluation_session', currentSession);

        // 이미지 파일들 추가
        if (imageData.length > 0) {
            imageData.forEach((file, index) => {
                formData.append(`evaluation_image_${index}`, file);
            });
        }

        console.log('=== SENDING EVALUATION DATA ===');
        console.log('RCM ID:', rcmId);
        console.log('Control Code:', controlCode);
        console.log('Current Session:', currentSession);
        console.log('Evaluation Data:', evaluation);
        console.log('FormData contents:');
        for (let pair of formData.entries()) {
            console.log(pair[0] + ': ' + (pair[1] instanceof File ? `File(${pair[1].name})` : pair[1]));
        }

        fetch('/api/design-evaluation/save', {
            method: 'POST',
            body: formData
        })
            .then(response => {
                console.log('Response status:', response.status);
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                console.log('Response data:', data);
                if (data.success) {
                    // 로컬 평가 결과에 evaluation_date 설정 (정식 평가 완료 표시)
                    evaluation.evaluation_date = new Date().toISOString();
                    evaluationResults[currentEvaluationIndex] = evaluation;

                    // UI 즉시 업데이트
                    updateEvaluationUI(currentEvaluationIndex, evaluation);
                    updateProgress();

                    // 서버에서 최신 데이터를 다시 로드하여 리스트 새로고침
                    // 저장 후에는 현재 세션의 최신 header_id를 사용하여 로드
                    loadExistingEvaluations();

                    // 성공 메시지 표시
                    showSuccessMessage('평가가 성공적으로 저장되었습니다.');

                    // 모달 닫기
                    const modal = bootstrap.Modal.getInstance(document.getElementById('evaluationModal'));
                    modal.hide();
                } else {
                    throw new Error(data.message || '저장에 실패했습니다.');
                }
            })
            .catch(error => {
                console.error('=== SAVE ERROR ===');
                console.error('Error type:', error.constructor.name);
                console.error('Error message:', error.message);
                console.error('Full error:', error);
                alert('[DESIGN-008] 저장 중 오류가 발생했습니다: ' + error.message);
            })
            .finally(() => {
                // 저장 버튼 복원
                saveButton.disabled = false;
                saveButton.innerHTML = originalText;
            });
        }

        // 평가 결과 UI 업데이트
        function updateEvaluationUI(index, evaluation) {
            try {
                const resultElement = document.getElementById(`result-${index}`);
                const actionElement = document.getElementById(`action-${index}`);
                const buttonElement = document.getElementById(`eval-btn-${index}`);

                // 필수 요소 체크
                if (!buttonElement) {
                    console.error(`Button element not found for index ${index}`);
                    return;
                }

                if (!resultElement) {
                    console.error(`Result element not found for index ${index}`);
                    return;
                }

                // actionElement는 선택적 (없어도 계속 진행)

                // 헤더 완료 상태 확인
                const headerCompletedDate = sessionStorage.getItem('headerCompletedDate');
                const isHeaderCompleted = headerCompletedDate && headerCompletedDate !== 'null' && headerCompletedDate !== null && headerCompletedDate.trim() !== '';

                // evaluation_date가 있을 때만 완료로 표시 (null, undefined, 빈 문자열 모두 제외)
                const hasValidEvaluationDate = evaluation.evaluation_date &&
                    evaluation.evaluation_date !== '' &&
                    evaluation.evaluation_date !== null &&
                    evaluation.evaluation_date !== 'null';

                // 임시평가 데이터인지 확인 (evaluation_date는 없지만 평가 데이터는 있는 경우)
                const isTemporaryEvaluation = !hasValidEvaluationDate &&
                    evaluation.description_adequacy &&
                    evaluation.overall_effectiveness;

                // 첫 번째 항목만 디버깅 로그 출력 (유연한 비교를 위해 == 사용)
                if (index == 1) {
                    console.log('=== updateEvaluationUI Debug (Index 1) ===');
                    console.log('headerCompletedDate:', headerCompletedDate);
                    console.log('isHeaderCompleted:', isHeaderCompleted);
                    console.log('hasValidEvaluationDate:', hasValidEvaluationDate);
                    console.log('isTemporaryEvaluation:', isTemporaryEvaluation);
                    console.log('evaluation_date:', evaluation.evaluation_date);
                    console.log('overall_effectiveness:', evaluation.overall_effectiveness);
                }

                if (hasValidEvaluationDate || isTemporaryEvaluation) {
                    // 결과 표시
                    let resultClass = '';
                    let resultText = '';

                    // overall_effectiveness가 있으면 표시
                    if (evaluation.overall_effectiveness) {
                        if (evaluation.overall_effectiveness === 'effective') {
                            resultClass = 'bg-success';
                            resultText = '적정';
                        } else if (evaluation.overall_effectiveness === 'ineffective' || evaluation.overall_effectiveness === 'partially_effective') {
                            // partially_effective, ineffective 모두 부적정
                            resultClass = 'bg-danger';
                            resultText = '부적정';
                        }
                    } else if (evaluation.description_adequacy) {
                        // overall_effectiveness가 없으면 description_adequacy로 판단
                        if (evaluation.description_adequacy === 'adequate') {
                            resultClass = 'bg-success';
                            resultText = '적정';
                        } else if (evaluation.description_adequacy === 'inadequate' || evaluation.description_adequacy === 'missing' || evaluation.description_adequacy === 'partially_adequate') {
                            // inadequate, missing, partially_adequate 모두 부적정
                            resultClass = 'bg-danger';
                            resultText = '부적정';
                        }
                    }

                    // 평가 결과 뱃지 업데이트 (중복 코드 제거 및 깔끔하게 처리)
                    if (resultText) {
                        resultElement.innerHTML = `<span class="badge ${resultClass}">${resultText}</span>`;
                    } else {
                        resultElement.innerHTML = '<span class="text-muted">-</span>';
                    }

                    if (actionElement) {
                        actionElement.innerHTML = evaluation.recommended_actions || '<span class="text-muted">-</span>';
                    }

                    // 버튼 상태 변경 - 완료
                    if (isHeaderCompleted) {
                        // 헤더 완료 시 버튼 상태 변경 (조회용으로 활성화)
                        if (index === 1) console.log('Setting button to 조회 (header completed)');
                        buttonElement.innerHTML = '<i class="fas fa-eye me-1"></i>조회';
                        buttonElement.className = 'btn btn-sm btn-outline-info';
                        buttonElement.disabled = false;
                        buttonElement.title = '평가 결과를 조회합니다';
                        buttonElement.setAttribute('data-bs-toggle', 'tooltip');
                        buttonElement.setAttribute('style', 'padding: 0.2rem 0.5rem; font-size: 0.75rem; min-width: 70px; white-space: nowrap;');
                        if (index === 1) {
                            console.log('Button innerHTML after update:', buttonElement.innerHTML);
                            console.log('Button outerHTML after update:', buttonElement.outerHTML);
                        }
                    } else {
                        if (index === 1) console.log('Setting button to 평가완료 (not completed)');
                        buttonElement.innerHTML = '<i class="fas fa-check me-1"></i>평가완료';
                        buttonElement.className = 'btn btn-sm btn-success';
                        buttonElement.disabled = false;
                        buttonElement.title = '평가 결과를 수정합니다';
                        buttonElement.setAttribute('data-bs-toggle', 'tooltip');
                        buttonElement.setAttribute('style', 'padding: 0.2rem 0.5rem; font-size: 0.75rem; min-width: 70px; white-space: nowrap;');
                        if (index === 1) {
                            console.log('Button innerHTML after update:', buttonElement.innerHTML);
                            console.log('Button outerHTML after update:', buttonElement.outerHTML);
                        }
                    }
                } else {
                    // evaluation_date가 없고 임시평가도 아니면 공란으로 표시
                    resultElement.innerHTML = '<span class="text-muted"></span>';
                    if (actionElement) {
                        actionElement.innerHTML = '<span class="text-muted">-</span>';
                    }

                    // 버튼 상태 - 미완료
                    if (isHeaderCompleted) {
                        // 헤더 완료 시 버튼 상태 변경 (조회용으로 활성화)
                        buttonElement.innerHTML = '<i class="fas fa-eye me-1"></i>조회';
                        buttonElement.classList.remove('btn-success', 'btn-outline-success', 'btn-secondary');
                        buttonElement.classList.add('btn-sm', 'btn-outline-info');
                        buttonElement.disabled = false;
                        buttonElement.style.padding = '0.2rem 0.5rem';
                        buttonElement.style.fontSize = '0.75rem';
                        buttonElement.style.height = 'auto';
                        buttonElement.style.width = 'auto';
                        buttonElement.style.minWidth = '70px';
                        buttonElement.title = '평가 결과를 조회합니다';
                        buttonElement.setAttribute('data-bs-toggle', 'tooltip');
                    } else {
                        buttonElement.innerHTML = '<i class="fas fa-edit me-1"></i>평가';
                        buttonElement.classList.remove('btn-success', 'btn-secondary', 'btn-outline-secondary');
                        buttonElement.classList.add('btn-sm', 'btn-outline-success');
                        buttonElement.disabled = false;
                        buttonElement.title = '평가를 시작합니다';
                        buttonElement.setAttribute('data-bs-toggle', 'tooltip');
                        buttonElement.style.padding = '0.2rem 0.5rem';
                        buttonElement.style.fontSize = '0.75rem';
                        buttonElement.style.height = 'auto';
                        buttonElement.style.width = 'auto';
                    }
                }

                // 툴팁 다시 초기화 (동적으로 변경된 버튼들을 위해)
                if (window.initializeTooltips) {
                    window.initializeTooltips();
                }

                // 동적으로 생성된 버튼에 툴팁 속성 추가
                if (buttonElement.title) {
                    buttonElement.setAttribute('data-bs-toggle', 'tooltip');
                }
            } catch (error) {
                console.error(`Error in updateEvaluationUI for index ${index}:`, error);
            }
        }

        // 진행률 업데이트 (header completed_date 기반)
        function updateProgress() {
            const totalControls = {{ rcm_details| length}};
        let evaluatedCount = 0;

        // evaluation_date가 있는 항목만 개별 완료로 계산 (완료 버튼 표시용)
        Object.values(evaluationResults).forEach(evaluation => {
            if (evaluation.evaluation_date) {
                evaluatedCount++;
            }
        });

        // 디버깅 로그
        console.log('=== updateProgress Debug ===');
        console.log(`총 통제 수: ${totalControls}`);
        console.log(`평가 완료 수: ${evaluatedCount}`);
        console.log(`평가 결과 객체 수: ${Object.keys(evaluationResults).length}`);

        // header의 completed_date가 있으면 전체 완료 상태
        const headerCompletedDate = sessionStorage.getItem('headerCompletedDate');
        const isCompleted = headerCompletedDate && headerCompletedDate !== 'null' && headerCompletedDate !== null && headerCompletedDate.trim() !== '';
        console.log(`headerCompletedDate: ${headerCompletedDate}`);
        console.log(`isCompleted: ${isCompleted}`);

        let progress, statusText, statusClass;

        if (isCompleted) {
            // 헤더에 완료일이 있으면 100% 완료
            progress = 100;
            statusText = '완료';
            statusClass = 'bg-success';
        } else {
            // 개별 평가 진행률로 표시
            progress = Math.round((evaluatedCount / totalControls) * 100);
            statusText = '진행중';
            statusClass = 'bg-primary';
        }

        document.getElementById('evaluationProgress').style.width = `${progress}%`;
        document.getElementById('evaluationProgress').setAttribute('aria-valuenow', progress);
        document.getElementById('evaluationProgress').textContent = `${progress}%`;
        document.getElementById('evaluatedCount').textContent = evaluatedCount;

        // 버튼 요소 가져오기
        const completeBtn = document.getElementById('completeEvaluationBtn');
        const archiveBtn = document.getElementById('archiveEvaluationBtn');
        const downloadBtn = document.getElementById('downloadBtn');

        console.log(`completeBtn 요소:`, completeBtn);
        console.log(`버튼 표시 조건 - isCompleted: ${isCompleted}, evaluatedCount === totalControls: ${evaluatedCount === totalControls}`);

        // 버튼 표시 및 텍스트 설정
        if (isCompleted) {
            // 완료 상태면 완료취소 버튼 표시
            console.log('완료 상태: 완료취소 버튼 표시');
            completeBtn.style.display = 'block';
            completeBtn.innerHTML = '<i class="fas fa-undo me-1"></i>완료취소';
            completeBtn.className = 'btn btn-sm btn-outline-warning';
            completeBtn.style.height = '70%';
            completeBtn.style.padding = '0.2rem 0.5rem';
            completeBtn.title = '설계평가 완료를 취소합니다';
            completeBtn.disabled = false;  // 명시적으로 활성화
            completeBtn.setAttribute('data-bs-toggle', 'tooltip');

            // 완료 상태에서만 Archive 버튼과 다운로드 버튼 표시
            archiveBtn.style.display = 'block';
            downloadBtn.style.display = 'block';
        } else if (evaluatedCount === totalControls) {
            // 모든 개별 평가가 완료되었지만 헤더 완료가 안된 경우
            console.log('평가 완료: 완료처리 버튼 표시');
            completeBtn.style.display = 'block';
            completeBtn.innerHTML = '<i class="fas fa-check me-1"></i>완료처리';
            completeBtn.className = 'btn btn-sm btn-success';
            completeBtn.style.height = '70%';
            completeBtn.style.padding = '0.2rem 0.5rem';
            completeBtn.title = '설계평가를 완료 처리합니다';
            completeBtn.disabled = false;  // 명시적으로 활성화
            completeBtn.setAttribute('data-bs-toggle', 'tooltip');

            // 아직 완료되지 않았으므로 Archive 버튼과 다운로드 버튼 숨김
            archiveBtn.style.display = 'none';
            downloadBtn.style.display = 'none';
        } else {
            completeBtn.style.display = 'none';
            archiveBtn.style.display = 'none';
            downloadBtn.style.display = 'none';
        }
        }

        // 전체 평가 (샘플 데이터로 자동 평가 - 임시 데이터만 표시, 저장하지 않음)
        function evaluateAllControls() {
            if (!confirm('모든 통제에 대해 샘플 설계평가를 수행하시겠습니까?\n\n⚠️ 주의사항:\n- 이 기능은 임시 데이터를 생성하여 화면에만 표시합니다\n- 실제로 데이터베이스에 저장되지 않습니다\n- 실제 업무에서는 각 통제를 개별적으로 검토해야 합니다')) {
                return;
            }

            const totalControls = {{ rcm_details| length}};

        for (let i = 1; i <= totalControls; i++) {
            // evaluation_date가 없는 통제만 평가 (미완료 통제)
            if (!evaluationResults[i] || !evaluationResults[i].evaluation_date) {
                // 현실적인 분포로 적정도 선택 (적절함 60%, 부분적으로 적절함 25%, 부적절함 10%, 누락 5%)
                const adequacyRand = Math.random();
                let adequacy;
                if (adequacyRand < 0.6) {
                    adequacy = 'adequate';
                } else if (adequacyRand < 0.85) {
                    adequacy = 'partially_adequate';
                } else if (adequacyRand < 0.95) {
                    adequacy = 'inadequate';
                } else {
                    adequacy = 'missing';
                }

                // 현실적인 분포로 효과성 선택 (효과적 55%, 부분적으로 효과적 35%, 비효과적 10%)
                const effectivenessRand = Math.random();
                let effectiveness;
                if (effectivenessRand < 0.55) {
                    effectiveness = 'effective';
                } else if (effectivenessRand < 0.9) {
                    effectiveness = 'partially_effective';
                } else {
                    effectiveness = 'ineffective';
                }

                let improvementText = '';
                let actionText = '';

                if (adequacy === 'inadequate' || adequacy === 'missing') {
                    improvementText = '통제활동 설명을 보다 구체적이고 명확하게 기술하여 실행 담당자가 이해하기 쉽도록 개선이 필요합니다.';
                }

                if (effectiveness === 'partially_effective' || effectiveness === 'ineffective') {
                    actionText = '통제 설계의 효과성 개선을 위한 추가 검토 및 보완 조치가 필요합니다.';
                }

                const evaluation = {
                    adequacy: adequacy,
                    improvement: improvementText,
                    effectiveness: effectiveness,
                    rationale: '자동 평가로 생성된 샘플 평가 근거입니다. 실제로는 상세한 검토가 필요합니다.',
                    actions: actionText
                };

                // 임시 데이터로만 화면에 표시 (서버에 저장하지 않음)
                evaluationResults[i] = evaluation;
                updateEvaluationUI(i, evaluation);

                // evaluation_date는 설정하지 않음 (저장되지 않은 임시 데이터이므로)
            }
        }

        alert('[DESIGN-009] 임시 설계평가 데이터가 생성되었습니다.\n\n📢 안내사항:\n- 화면에 표시된 데이터는 임시 데이터입니다\n- 실제로 저장되지 않았습니다\n- 개별 통제를 클릭하여 실제 평가를 수행해주세요');

            // 임시 데이터이므로 서버에서 다시 로드하지 않음
        }

        // 전체 통제를 "적정" 값으로 실제 저장
        function saveAllAsAdequate() {
            if (!confirm('모든 통제를 "적절함 + 효과적"으로 실제 저장하시겠습니까?\n\n⚠️ 주의사항:\n- 이 작업은 실제로 데이터베이스에 저장됩니다\n- 이미 평가된 통제는 덮어쓰여집니다\n- 모든 통제가 "적절함 + 효과적"으로 저장됩니다')) {
                return;
            }

            const currentSession = sessionStorage.getItem('currentEvaluationSession');
            if (!currentSession) {
                alert('[DESIGN-010] 평가 세션을 먼저 생성해주세요.');
                return;
            }

            const totalControls = {{ rcm_details| length}};
        let savedCount = 0;
        let errors = [];

        // 각 통제에 대해 순차적으로 적정 값으로 저장
        function saveNext(index) {
            if (index > totalControls) {
                // 모든 저장 완료
                if (errors.length > 0) {
                    alert(`[DESIGN-011] 저장 완료!\n성공: ${savedCount}개\n실패: ${errors.length}개\n\n실패 목록:\n${errors.join('\n')}`);
                } else {
                    alert(`[DESIGN-012] 모든 통제가 "적절함 + 효과적"으로 저장되었습니다!\n총 ${savedCount}개 통제 저장 완료`);
                }

                // UI 업데이트 - 페이지 새로고침으로 데이터 다시 로드
                window.location.reload();
                return;
            }

            // 통제 코드 찾기
            let controlCode = null;
            {% for detail in rcm_details %}
            if ({{ loop.index }} === index) {
            controlCode = '{{ detail.control_code }}';
        }
        {% endfor %}

        if (!controlCode) {
            saveNext(index + 1);
            return;
        }

        // 모든 통제를 "적절함 + 효과적"으로 저장
        const evaluationData = {
            description_adequacy: 'adequate',
            improvement_suggestion: '',
            overall_effectiveness: 'effective',
            evaluation_rationale: '',
            recommended_actions: ''
        };

        // 서버에 저장
        fetch('/api/design-evaluation/save', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'same-origin',
            body: JSON.stringify({
                rcm_id: {{ rcm_id }},
            control_code: controlCode,
            evaluation_data: evaluationData,
            evaluation_session: currentSession
                    })
                })
                .then(response => response.json())
            .then(data => {
                console.log(`${controlCode} 저장 결과:`, data);
                if (data.success) {
                    savedCount++;
                } else {
                    const errorMsg = `${controlCode}: ${data.message || '알 수 없는 오류'}`;
                    console.error(errorMsg);
                    errors.push(errorMsg);
                }
                // 다음 통제 저장
                saveNext(index + 1);
            })
            .catch(error => {
                const errorMsg = `${controlCode}: ${error.message || '네트워크 오류'}`;
                console.error('저장 실패:', errorMsg, error);
                errors.push(errorMsg);
                // 다음 통제 저장
                saveNext(index + 1);
            });
            }

        // 첫 번째 통제부터 시작
        saveNext(1);
        }

        // 평가 완료/완료취소 처리
        function completeEvaluation() {
            const currentSession = sessionStorage.getItem('currentEvaluationSession');
            if (!currentSession) {
                alert('[DESIGN-013] 평가 세션 정보를 찾을 수 없습니다.');
                return;
            }

            const headerCompletedDate = sessionStorage.getItem('headerCompletedDate');
            const isCompleted = headerCompletedDate && headerCompletedDate !== 'null' && headerCompletedDate !== null && headerCompletedDate.trim() !== '';
            const completeBtn = document.getElementById('completeEvaluationBtn');

            if (isCompleted) {
                // 완료취소 처리 - 기본 확인 메시지 (운영평가 여부는 서버에서 확인)
                if (!confirm('설계평가 완료를 취소하시겠습니까?\n\n완료 취소 후에는 평가 상태가 "진행중"으로 변경됩니다.')) {
                    return;
                }

                const originalText = completeBtn.innerHTML;
                completeBtn.disabled = true;
                completeBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>취소 중...';

                fetch('/api/design-evaluation/cancel', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    credentials: 'same-origin',
                    body: JSON.stringify({
                        rcm_id: {{ rcm_id }},
                    evaluation_session: currentSession
                    })
        })
                .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // 운영평가가 있는 경우 추가 알림
                    if (data.has_operation_evaluation) {
                        alert('⚠️ 참고: 이 설계평가를 기반으로 한 운영평가가 진행중입니다.\n\n설계평가를 다시 완료처리해야 운영평가를 이어서 진행할 수 있습니다.');
                    }
                    // sessionStorage에서 완료일 제거 (더 확실하게)
                    sessionStorage.removeItem('headerCompletedDate');
                    sessionStorage.setItem('headerCompletedDate', '');
                    sessionStorage.removeItem('headerCompletedDate');
                    console.log('HeaderCompletedDate removed from sessionStorage');
                    console.log('SessionStorage check after removal:', sessionStorage.getItem('headerCompletedDate'));

                    // 진행률 업데이트
                    updateProgress();

                    // 모든 개별 평가 항목의 UI 업데이트 (버튼 상태 변경)
                    console.log('완료 취소 후 UI 업데이트 시작');
                    Object.keys(evaluationResults).forEach(index => {
                        if (evaluationResults[index]) {
                            console.log(`Index ${index} UI 업데이트 중...`);
                            updateEvaluationUI(index, evaluationResults[index]);

                            // 버튼 상태 재확인
                            const btn = document.getElementById(`eval-btn-${index}`);
                            console.log(`Button ${index} 상태 - disabled: ${btn.disabled}, innerHTML: ${btn.innerHTML}`);
                        }
                    });
                    console.log('완료 취소 후 UI 업데이트 완료');

                } else {
                    alert('[DESIGN-014] 완료 취소 중 오류가 발생했습니다: ' + data.message);
                    // 버튼 원복
                    completeBtn.disabled = false;
                    completeBtn.innerHTML = originalText;
                }
            })
            .catch(error => {
                console.error('완료 취소 오류:', error);
                alert('[DESIGN-015] 완료 취소 중 오류가 발생했습니다: ' + error.message);
                // 버튼 원복
                completeBtn.disabled = false;
                completeBtn.innerHTML = originalText;
            });
            } else {
            // 완료 처리 전 효과적이지 않은 통제 확인
            const ineffectiveControls = [];
            Object.keys(evaluationResults).forEach(index => {
                const evaluation = evaluationResults[index];
                if (evaluation && evaluation.overall_effectiveness) {
                    if (evaluation.overall_effectiveness === 'partially_effective' ||
                        evaluation.overall_effectiveness === 'ineffective') {
                        // 통제 코드 찾기
                        const controlCode = {% for detail in rcm_details %}
                    {{ loop.index }} === parseInt(index) ? '{{ detail.control_code }}' :
                        {% endfor %} null;

                if (controlCode) {
                    const effectivenessText = evaluation.overall_effectiveness === 'partially_effective'
                        ? '부분적으로 효과적'
                        : '비효과적';
                    ineffectiveControls.push(`${controlCode} (${effectivenessText})`);
                }
            }
                    }
                });

        // 효과적이지 않은 통제가 있는 경우 경고 메시지
        let confirmMessage = '설계평가를 완료 처리하시겠습니까?\n\n완료 처리 후에는 평가 상태가 "완료"로 변경되며,\n완료일시가 기록됩니다.';

        if (ineffectiveControls.length > 0) {
            confirmMessage = `⚠️ 효과적이지 않은 통제가 있습니다:\n\n${ineffectiveControls.join('\n')}\n\n그래도 완료 처리하시겠습니까?`;
        }

        if (!confirm(confirmMessage)) {
            return;
        }

        const originalText = completeBtn.innerHTML;
        completeBtn.disabled = true;
        completeBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>처리 중...';

        fetch('/api/design-evaluation/complete', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'same-origin',
            body: JSON.stringify({
                rcm_id: {{ rcm_id }},
            evaluation_session: currentSession
                    })
                })
                .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // sessionStorage에 완료일 저장
                    sessionStorage.setItem('headerCompletedDate', data.completed_date);

                    // 진행률 업데이트 (새로운 로직 사용)
                    updateProgress();

                    // 모든 개별 평가 항목의 UI 즉시 업데이트 (버튼을 "완료됨"으로 변경)
                    Object.keys(evaluationResults).forEach(index => {
                        if (evaluationResults[index]) {
                            updateEvaluationUI(index, evaluationResults[index]);
                        }
                    });

                } else {
                    alert('[DESIGN-016] 완료 처리 중 오류가 발생했습니다: ' + data.message);
                    // 버튼 원복
                    completeBtn.disabled = false;
                    completeBtn.innerHTML = originalText;
                }
            })
            .catch(error => {
                console.error('완료 처리 오류:', error);
                alert('[DESIGN-017] 완료 처리 중 오류가 발생했습니다: ' + error.message);
                // 버튼 원복
                completeBtn.disabled = false;
                completeBtn.innerHTML = originalText;
            });
            }
        }

        // 평가 Archive 처리
        function archiveEvaluation() {
            const currentSession = sessionStorage.getItem('currentEvaluationSession');
            if (!currentSession) {
                alert('[DESIGN-018] 평가 세션 정보를 찾을 수 없습니다.');
                return;
            }

            const headerCompletedDate = sessionStorage.getItem('headerCompletedDate');
            const isCompleted = headerCompletedDate && headerCompletedDate !== 'null' && headerCompletedDate !== null && headerCompletedDate.trim() !== '';

            if (!isCompleted) {
                alert('[DESIGN-019] 완료된 설계평가만 Archive 처리할 수 있습니다.');
                return;
            }

            if (!confirm(`설계평가 세션 "${currentSession}"을 Archive 처리하시겠습니까?\n\nArchive 처리하면 해당 세션이 목록에서 숨겨지며,\n필요시 복원할 수 있습니다.`)) {
                return;
            }

            const archiveBtn = document.getElementById('archiveEvaluationBtn');
            const originalText = archiveBtn.innerHTML;
            archiveBtn.disabled = true;
            archiveBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>처리 중...';

            fetch('/api/design-evaluation/archive', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                credentials: 'same-origin',
                body: JSON.stringify({
                    rcm_id: {{ rcm_id }},
                evaluation_session: currentSession
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Archive 처리가 완료되었습니다.');
                    // 설계평가 목록 페이지로 이동
                    window.location.href = '/user/design-evaluation';
                } else {
                    alert('[DESIGN-020] Archive 처리 중 오류가 발생했습니다: ' + data.message);
                    // 버튼 원복
                    archiveBtn.disabled = false;
                    archiveBtn.innerHTML = originalText;
                }
            })
            .catch(error => {
                console.error('Archive 처리 오류:', error);
                alert('[DESIGN-021] Archive 처리 중 오류가 발생했습니다: ' + error.message);
                // 버튼 원복
                archiveBtn.disabled = false;
                archiveBtn.innerHTML = originalText;
            });
        }

        // 서버에 평가 결과 저장 (전체 평가용)
        function saveEvaluationToServer(controlIndex, evaluation) {
            const currentSession = sessionStorage.getItem('currentEvaluationSession');
            if (!currentSession) {
                console.error('평가 세션 정보가 없습니다.');
                return;
            }

            // 컨트롤 코드 찾기
            let controlCode = null;
            {% for detail in rcm_details %}
            if ({{ loop.index }} === controlIndex) {
            controlCode = '{{ detail.control_code }}';
        }
        {% endfor %}

        if (!controlCode) {
            console.error('통제 코드를 찾을 수 없습니다.');
            return;
        }

        const requestData = {
            rcm_id: rcmId,
            control_code: controlCode,
            evaluation_data: evaluation,
            evaluation_session: currentSession
        };

        fetch('/api/design-evaluation/save', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestData)
        })
            .then(response => response.json())
            .then(data => {
                if (!data.success) {
                    console.error(`통제 ${controlCode} 저장 실패:`, data.message);
                }
            })
            .catch(error => {
                console.error(`통제 ${controlCode} 저장 오류:`, error);
            });
        }

        // 평가 초기화
        function resetAllEvaluations() {
            if (!confirm('모든 설계평가 결과를 초기화하시겠습니까?\n이 작업은 되돌릴 수 없습니다.')) {
                return;
            }

            // 서버에서 평가 데이터 삭제
            fetch('/api/design-evaluation/reset', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    rcm_id: rcmId
                })
            })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // 로컬 데이터 초기화
                        evaluationResults = {};

                        // UI 초기화
                        const totalControls = {{ rcm_details| length}};
            for (let i = 1; i <= totalControls; i++) {
                resetEvaluationUI(i);
            }

            // 진행률 초기화
            updateProgress();

            alert('[DESIGN-018] 모든 설계평가가 초기화되었습니다.');
        } else {
            alert('[DESIGN-019] 초기화 실패: ' + data.message);
        }
            })
            .catch (error => {
            console.error('초기화 오류:', error);
            alert('[DESIGN-020] 초기화 중 오류가 발생했습니다.');
        });
        }

        // 개별 평가 UI 초기화
        function resetEvaluationUI(index) {
            const resultElement = document.getElementById(`result-${index}`);
            const actionElement = document.getElementById(`action-${index}`);
            const buttonElement = document.getElementById(`eval-btn-${index}`);

            // 결과 초기화
            if (resultElement) {
                resultElement.innerHTML = '<span class="text-muted"></span>';
            }
            if (actionElement) {
                actionElement.innerHTML = '<span class="text-muted">-</span>';
            }

            // 버튼 초기화
            buttonElement.innerHTML = '<i class="fas fa-clipboard-check me-1"></i>평가';
            buttonElement.classList.remove('btn-success');
            buttonElement.classList.add('btn-outline-success');
        }

        // 평가 결과 다운로드
        function exportEvaluationResult() {
            // 새로운 엑셀 다운로드 API 호출
            const downloadUrl = `/api/design-evaluation/download-excel/{{ rcm_id }}`;

            // 로딩 표시
            const downloadBtn = document.getElementById('downloadBtn');
            const originalText = downloadBtn.innerHTML;
            downloadBtn.disabled = true;
            downloadBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>생성 중...';

            // 새 창에서 다운로드 실행
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.target = '_blank';
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);

            // 버튼 상태 복원 (약간의 딜레이 후)
            setTimeout(() => {
                downloadBtn.disabled = false;
                downloadBtn.innerHTML = originalText;
            }, 2000);
        }


        // 평가 목록 새로고침
        function refreshEvaluationList() {
            console.log('평가 목록 새로고침 시작...');

            // 버튼 찾기
            const refreshBtn = event.target.closest('button');
            if (!refreshBtn) {
                console.error('새로고침 버튼을 찾을 수 없습니다.');
                return;
            }

            // 버튼 상태 변경
            const originalHTML = refreshBtn.innerHTML;
            refreshBtn.disabled = true;
            refreshBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>로딩 중...';

            // 아이콘 회전 애니메이션
            const icon = refreshBtn.querySelector('i');
            if (icon) {
                icon.classList.add('fa-spin');
            }

            // 기존 평가 데이터 다시 로드
            loadExistingEvaluations();

            // 진행률 업데이트
            updateProgress();

            // 버튼 복원 (1초 후)
            setTimeout(() => {
                refreshBtn.disabled = false;
                refreshBtn.innerHTML = originalHTML;
                showSuccessMessage('평가 목록이 새로고침되었습니다.');
            }, 1000);
        }

        // 샘플 업로드 모달 표시 (일괄 업로드용)
        function showSampleUploadModal() {
            const modal = new bootstrap.Modal(document.getElementById('sampleUploadModal'));
            modal.show();
        }

        // 샘플 템플릿 다운로드
        function downloadSampleTemplate() {
            // 현재 RCM의 통제 코드를 기반으로 샘플 템플릿 생성
            let csv = '통제코드,설명적절성,개선제안,종합효과성,평가근거,권고조치사항\n';

            {% for detail in rcm_details %}
            csv += `"{{ detail.control_code }}","adequate","","effective","",""\n`;
            {% endfor %}

            // BOM 추가 (한글 깨짐 방지)
            const bom = '\uFEFF';
            const csvContent = bom + csv;

            // 다운로드
            const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            const link = document.createElement('a');
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', '{{ rcm_info.rcm_name }}_설계평가_템플릿.csv');
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        // 평가 파일 업로드
        function uploadEvaluationFile() {
            const fileInput = document.getElementById('evaluationFile');
            const file = fileInput.files[0];

            if (!file) {
                alert('업로드할 파일을 선택해주세요.');
                return;
            }

            // 파일 형식 확인
            const fileName = file.name.toLowerCase();
            if (!fileName.endsWith('.csv') && !fileName.endsWith('.xlsx') && !fileName.endsWith('.xls')) {
                alert('CSV 또는 Excel 파일만 업로드 가능합니다.');
                return;
            }

            // CSV 파일 처리
            if (fileName.endsWith('.csv')) {
                const reader = new FileReader();
                reader.onload = function (e) {
                    try {
                        processCsvData(e.target.result);
                    } catch (error) {
                        console.error('CSV 파싱 오류:', error);
                        alert('CSV 파일 처리 중 오류가 발생했습니다.');
                    }
                };
                reader.readAsText(file, 'UTF-8');
            } else {
                // Excel 파일은 서버에서 처리 필요
                alert('Excel 파일 처리는 향후 지원 예정입니다. 현재는 CSV 파일만 사용해주세요.');
            }
        }

        // CSV 데이터 처리
        function processCsvData(csvText) {
            const lines = csvText.split('\n');
            if (lines.length < 2) {
                alert('파일에 데이터가 없습니다.');
                return;
            }

            // 헤더 확인
            const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''));
            const expectedHeaders = ['통제코드', '설명적절성', '개선제안', '종합효과성', '평가근거', '권고조치사항'];

            // 통제코드 인덱스 맵 생성
            const controlCodeToIndex = {};
            {% for detail in rcm_details %}
            controlCodeToIndex['{{ detail.control_code }}'] = {{ loop.index }};
        {% endfor %}

        let uploadedCount = 0;
        const promises = [];

        // 데이터 행 처리
        for (let i = 1; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;

            const values = line.split(',').map(v => v.trim().replace(/"/g, ''));
            if (values.length < 6) continue;

            const controlCode = values[0];
            const index = controlCodeToIndex[controlCode];

            if (index) {
                const evaluation = {
                    adequacy: values[1] || '',
                    improvement: values[2] || '',
                    effectiveness: values[3] || '',
                    rationale: values[4] || '',
                    actions: values[5] || ''
                };

                // 서버에 저장
                const promise = fetch('/api/design-evaluation/save', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        rcm_id: rcmId,
                        control_code: controlCode,
                        evaluation_data: evaluation,
                        evaluation_session: sessionStorage.getItem('currentEvaluationSession')
                    })
                })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            // 로컬에 결과 저장
                            evaluationResults[index] = evaluation;
                            updateEvaluationUI(index, evaluation);
                            uploadedCount++;
                        }
                    });

                promises.push(promise);
            }
        }

        // 모든 업로드 완료 후 처리
        Promise.all(promises).then(() => {
            updateProgress();

            // 모달 닫기
            const modal = bootstrap.Modal.getInstance(document.getElementById('sampleUploadModal'));
            modal.hide();

            // 파일 입력 초기화
            document.getElementById('evaluationFile').value = '';

            alert(`${uploadedCount}개의 설계평가 결과가 업로드되었습니다.`);
        }).catch(error => {
            console.error('업로드 오류:', error);
            alert('일부 데이터 업로드 중 오류가 발생했습니다.');
        });
        }

        // 당기 발생사실 없음 체크 시 필드 토글 (설계평가용)
        function toggleNoOccurrenceDesign() {
            const noOccurrenceCheckbox = document.getElementById('no_occurrence_design');
            const noOccurrenceReasonSection = document.getElementById('no-occurrence-reason-section-design');
            const evidenceSection = document.getElementById('design-evidence-section');

            if (noOccurrenceCheckbox && noOccurrenceCheckbox.checked) {
                // 당기 발생사실 없음 체크 시 사유 입력란 표시, 증빙 테이블 숨김
                if (noOccurrenceReasonSection) {
                    noOccurrenceReasonSection.style.display = 'block';
                }
                if (evidenceSection) {
                    evidenceSection.style.display = 'none';
                }
            } else {
                // 체크 해제 시 사유 입력란 숨김, 증빙 테이블 표시
                if (noOccurrenceReasonSection) {
                    noOccurrenceReasonSection.style.display = 'none';
                }
                if (evidenceSection) {
                    evidenceSection.style.display = 'block';
                }
            }
        }

        // Bootstrap 툴팁 초기화
        document.addEventListener('DOMContentLoaded', function () {
            // 당기 발생사실 없음 체크박스 이벤트 리스너
            const noOccurrenceCheckbox = document.getElementById('no_occurrence_design');
            if (noOccurrenceCheckbox) {
                noOccurrenceCheckbox.addEventListener('change', toggleNoOccurrenceDesign);
            }

            // 기존 툴팁 초기화
            var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
            var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
                return new bootstrap.Tooltip(tooltipTriggerEl);
            });

            // 동적으로 생성되는 요소들을 위한 툴팁 초기화 함수
            window.initializeTooltips = function () {
                // 기존 툴팁 제거
                tooltipList.forEach(function (tooltip) {
                    tooltip.dispose();
                });

                // 새로운 툴팁 초기화 - data-bs-toggle="tooltip" 속성이 있는 요소들만
                var newTooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
                newTooltipTriggerList.forEach(function (el) {
                    new bootstrap.Tooltip(el);
                });

                // tooltipList 업데이트
                tooltipList = newTooltipTriggerList.map(function (tooltipTriggerEl) {
                    return new bootstrap.Tooltip(tooltipTriggerEl);
                });
            };
        });

        // 운영평가 보기 함수
        function viewOperationEvaluation() {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/operation-evaluation/rcm';

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = '{{ rcm_id }}';

            const sessionInput = document.createElement('input');
            sessionInput.type = 'hidden';
            sessionInput.name = 'design_evaluation_session';
            sessionInput.value = document.getElementById('currentEvaluationName').textContent;

            const actionInput = document.createElement('input');
            actionInput.type = 'hidden';
            actionInput.name = 'action';
            actionInput.value = 'continue';

            form.appendChild(rcmInput);
            form.appendChild(sessionInput);
            form.appendChild(actionInput);
            document.body.appendChild(form);
            form.submit();
        }

        // ==================== 기준통제 매핑 관련 기능 ====================
        let stdControlModalInstance = null;
        let currentMappingRcmDetailId = null;
        let currentMappingControlCode = null;
        let allStdControls = [];

        // 페이지 로드 시 모달 초기화
        document.addEventListener('DOMContentLoaded', function () {
            stdControlModalInstance = new bootstrap.Modal(document.getElementById('stdControlModal'));

            // 검색 입력 이벤트
            document.getElementById('std-control-search').addEventListener('input', function (e) {
                filterStdControls(e.target.value);
            });

            // 매핑 해제 버튼 이벤트
            document.getElementById('btn-unmap-std-control').addEventListener('click', unmapStdControl);
        });

        // 기준통제 매핑 모달 열기
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