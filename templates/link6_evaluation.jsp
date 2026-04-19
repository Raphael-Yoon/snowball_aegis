<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - {{ category }} 평가</title>
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

    <!-- Toast Container -->
    <div class="toast-container position-fixed top-0 end-0 p-3" style="z-index: 1100;">
        <div id="successToast" class="toast align-items-center text-bg-success border-0" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="d-flex">
                <div class="toast-body">
                    <i class="fas fa-check-circle me-2"></i><span id="toastMessage"></span>
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        </div>
    </div>

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h1><img src="{{ url_for('static', filename='img/' + category.lower() + '.jpg') }}" alt="{{ category }}" style="width: 40px; height: 40px; object-fit: cover; border-radius: 8px; margin-right: 12px;">{{ category }} 평가</h1>
                    <a href="/" class="btn btn-secondary">
                        <i class="fas fa-home me-1"></i>홈으로
                    </a>
                </div>
                <hr>
            </div>
        </div>

        <!-- 평가 소개 -->
        <div class="row mb-4">
            <div class="col-md-6">
                <div class="card border-success h-100">
                    <div class="card-header bg-success text-white" style="cursor: pointer;" data-bs-toggle="collapse" data-bs-target="#collapseDesignInfo">
                        <h5 class="mb-0">
                            <i class="fas fa-info-circle me-2"></i>설계평가
                            <i class="fas fa-chevron-down float-end"></i>
                        </h5>
                    </div>
                    <div id="collapseDesignInfo" class="collapse">
                        <div class="card-body">
                            <p class="card-text">
                                <strong>설계평가(Design Effectiveness Testing)</strong>는 RCM에 기록된 통제활동이 현재 실제 업무와 일치하는지를 확인하고, 실무적으로 효과적으로 운영되고 있는지를 평가하는 과정입니다.
                            </p>
                            <ul class="small">
                                <li><strong>목적:</strong> 문서상 통제와 실제 수행되는 통제의 일치성 확인 및 실무 효과성 검증</li>
                                <li><strong>범위:</strong> 통제 절차의 현실 반영도, 실제 운영 상태, 위험 완화 효과 검토</li>
                                <li><strong>결과:</strong> 실무와 문서 간 차이점 식별 및 통제 운영 개선방안 도출</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card border-warning h-100">
                    <div class="card-header bg-warning text-dark" style="cursor: pointer;" data-bs-toggle="collapse" data-bs-target="#collapseOperationInfo">
                        <h5 class="mb-0">
                            <i class="fas fa-info-circle me-2"></i>운영평가
                            <i class="fas fa-chevron-down float-end"></i>
                        </h5>
                    </div>
                    <div id="collapseOperationInfo" class="collapse">
                        <div class="card-body">
                            <p class="card-text">
                                <strong>운영평가(Operating Effectiveness Testing)</strong>는 설계평가가 완료된 통제가 실제로 의도된 대로 작동하고 있는지를 평가하는 과정입니다.
                            </p>
                            <ul class="small">
                                <li><strong>전제조건:</strong> 설계평가가 완료되어 통제 설계가 적정하다고 평가된 통제만 대상</li>
                                <li><strong>목적:</strong> 통제가 일정 기간 동안 일관되게 효과적으로 운영되고 있는지 검증</li>
                                <li><strong>범위:</strong> 통제의 실행, 모니터링, 예외 처리 등 운영 현황 전반</li>
                                <li><strong>결과:</strong> 운영 효과성 결론 및 운영상 개선점 도출</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 내부평가 시작 버튼 -->
        <div class="row mb-4">
            <div class="col-12">
                <button type="button" class="btn btn-primary btn-lg w-100" onclick="showDesignEvaluationStartModal()" style="padding: 12px 20px;">
                    <i class="fas fa-plus-circle me-2"></i>내부평가 시작
                </button>
            </div>
        </div>

        <!-- 평가 현황 -->
        <div class="row mb-4">
            <!-- 설계평가 현황 -->
            <div class="col-md-6">
                <div class="card h-100">
                    <div class="card-header bg-success text-white">
                        <h5 class="mb-0"><i class="fas fa-clipboard-check me-2"></i>설계평가 현황</h5>
                    </div>
                    <div class="card-body">
                        {% if rcms %}
                        {% set has_design_sessions = rcms|selectattr('has_design_sessions')|list|length > 0 %}
                        {% if has_design_sessions %}
                        <div class="accordion" id="designEvaluationAccordion">
                            {% for rcm in rcms %}
                            {% if rcm.has_design_sessions %}
                            <div class="accordion-item">
                                <h2 class="accordion-header" id="heading{{ rcm.rcm_id }}">
                                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapse{{ rcm.rcm_id }}">
                                        <i class="fas fa-file-alt me-2"></i>{{ rcm.rcm_name }}
                                        {% set completed_count = rcm.design_sessions|selectattr('is_completed')|list|length %}
                                        {% set in_progress_count = rcm.design_sessions|length - completed_count %}
                                        {% if completed_count > 0 %}
                                        <span class="badge bg-success ms-2">완료 {{ completed_count }}개</span>
                                        {% endif %}
                                        {% if in_progress_count > 0 %}
                                        <span class="badge bg-warning text-dark ms-2">진행중 {{ in_progress_count }}개</span>
                                        {% endif %}
                                    </button>
                                </h2>
                                <div id="collapse{{ rcm.rcm_id }}" class="accordion-collapse collapse" data-bs-parent="#designEvaluationAccordion">
                                    <div class="accordion-body">
                                        <div class="table-responsive">
                                            <table class="table table-sm">
                                                <thead>
                                                    <tr>
                                                        <th>평가명</th>
                                                        <th>진행률</th>
                                                        <th>최종 업데이트</th>
                                                        <th>작업</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    {% for session in rcm.design_sessions %}
                                                    <tr>
                                                        <td>
                                                            {% if session.is_completed %}
                                                            <i class="fas fa-check-circle text-success me-1"></i>
                                                            {% else %}
                                                            <i class="fas fa-spinner text-warning me-1"></i>
                                                            {% endif %}
                                                            {{ session.evaluation_session }}
                                                        </td>
                                                        <td>
                                                            <div class="progress" style="width: 100px; height: 20px;">
                                                                <div class="progress-bar {% if session.is_completed %}bg-success{% else %}bg-warning{% endif %}"
                                                                     role="progressbar" style="width: {{ session.progress }}%">
                                                                    {{ session.progress }}%
                                                                </div>
                                                            </div>
                                                        </td>
                                                        <td>{{ session.last_updated[:10] if session.last_updated else '-' }}</td>
                                                        <td>
                                                            {% if not session.is_completed %}
                                                            <button class="btn btn-sm btn-primary me-1" onclick="continueDesignEvaluation({{ rcm.rcm_id }}, '{{ session.evaluation_session }}')">
                                                                <i class="fas fa-play me-1"></i>계속하기
                                                            </button>
                                                            <button class="btn btn-sm btn-danger" onclick="deleteEvaluation({{ session.header_id }}, '{{ session.evaluation_session }}')">
                                                                <i class="fas fa-trash me-1"></i>삭제
                                                            </button>
                                                            {% else %}
                                                            <button class="btn btn-sm btn-outline-secondary me-1" onclick="viewDesignEvaluation({{ rcm.rcm_id }}, '{{ session.evaluation_session }}')">
                                                                <i class="fas fa-eye me-1"></i>보기
                                                            </button>
                                                            <button class="btn btn-sm btn-danger" onclick="deleteEvaluation({{ session.header_id }}, '{{ session.evaluation_session }}')">
                                                                <i class="fas fa-trash me-1"></i>삭제
                                                            </button>
                                                            {% endif %}
                                                        </td>
                                                    </tr>
                                                    {% endfor %}
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            {% endif %}
                            {% endfor %}
                        </div>
                        {% else %}
                        <div class="text-center py-4">
                            <i class="fas fa-clipboard fa-2x text-muted mb-2"></i>
                            <p class="text-muted">설계평가 세션이 없습니다.</p>
                            <small class="text-muted">"내부평가 시작" 버튼을 클릭하여 새 평가를 시작하세요.</small>
                        </div>
                        {% endif %}
                        {% else %}
                        <div class="text-center py-4">
                            <p class="text-muted">접근 가능한 RCM이 없습니다.</p>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>

            <!-- 운영평가 현황 -->
            <div class="col-md-6">
                <div class="card h-100">
                    <div class="card-header bg-warning text-dark">
                        <h5 class="mb-0"><i class="fas fa-chart-line me-2"></i>운영평가 현황</h5>
                    </div>
                    <div class="card-body">
                        {% if rcms %}
                        {% set has_any_sessions = namespace(found=false) %}
                        {% for rcm in rcms %}
                        {% if rcm.has_operation_sessions or rcm.design_sessions|selectattr('status', 'equalto', 1)|list|length > 0 %}
                        {% set has_any_sessions.found = true %}
                        {% endif %}
                        {% endfor %}
                        {% if has_any_sessions.found %}
                        <div class="accordion" id="operationEvaluationAccordion">
                            {% for rcm in rcms %}
                            {% if rcm.has_operation_sessions or rcm.design_sessions|selectattr('status', 'equalto', 1)|list|length > 0 %}
                            <div class="accordion-item">
                                <h2 class="accordion-header" id="opheading{{ rcm.rcm_id }}">
                                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#opcollapse{{ rcm.rcm_id }}">
                                        <i class="fas fa-file-alt me-2"></i>{{ rcm.rcm_name }}
                                        {% set completed_count = rcm.operation_sessions|selectattr('status', 'equalto', 4)|list|length %}
                                        {% set in_progress_count = rcm.operation_sessions|selectattr('status', 'equalto', 3)|list|length %}
                                        {% if completed_count > 0 %}
                                        <span class="badge bg-success ms-2">완료 {{ completed_count }}개</span>
                                        {% endif %}
                                        {% if in_progress_count > 0 %}
                                        <span class="badge bg-warning text-dark ms-2">진행중 {{ in_progress_count }}개</span>
                                        {% endif %}
                                    </button>
                                </h2>
                                <div id="opcollapse{{ rcm.rcm_id }}" class="accordion-collapse collapse" data-bs-parent="#operationEvaluationAccordion">
                                    <div class="accordion-body">
                                        <div class="table-responsive">
                                            <table class="table table-sm">
                                                <thead>
                                                    <tr>
                                                        <th>평가명</th>
                                                        <th>진행률</th>
                                                        <th>최종 업데이트</th>
                                                        <th>작업</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    {% for session in rcm.operation_sessions %}
                                                    <tr>
                                                        <td>
                                                            {% if session.is_completed %}
                                                            <i class="fas fa-check-circle text-success me-1"></i>
                                                            {% else %}
                                                            <i class="fas fa-spinner text-warning me-1"></i>
                                                            {% endif %}
                                                            {{ session.evaluation_session }}
                                                        </td>
                                                        <td>
                                                            <div class="progress" style="width: 100px; height: 20px;">
                                                                <div class="progress-bar {% if session.is_completed %}bg-success{% else %}bg-warning{% endif %}"
                                                                     role="progressbar" style="width: {{ session.progress }}%">
                                                                    {{ session.progress }}%
                                                                </div>
                                                            </div>
                                                            <small class="text-muted">{{ session.operation_completed_count }}/{{ session.eligible_control_count }} 통제</small>
                                                        </td>
                                                        <td>{{ session.last_updated[:10] if session.last_updated else '-' }}</td>
                                                        <td>
                                                            {% if session.status == 2 %}
                                                            <button class="btn btn-sm btn-success me-1" style="min-width: 90px;" onclick="continueOperationEvaluation({{ rcm.rcm_id }}, '{{ session.design_evaluation_name }}')">
                                                                <i class="fas fa-play-circle me-1"></i>시작하기
                                                            </button>
                                                            <button class="btn btn-sm btn-danger" onclick="deleteEvaluation({{ session.header_id }}, '{{ session.evaluation_session }}')">
                                                                <i class="fas fa-trash me-1"></i>삭제
                                                            </button>
                                                            {% elif session.status == 3 %}
                                                            <button class="btn btn-sm btn-warning me-1" style="min-width: 90px;" onclick="continueOperationEvaluation({{ rcm.rcm_id }}, '{{ session.design_evaluation_name }}')">
                                                                <i class="fas fa-play me-1"></i>계속하기
                                                            </button>
                                                            <button class="btn btn-sm btn-danger" onclick="deleteEvaluation({{ session.header_id }}, '{{ session.evaluation_session }}')">
                                                                <i class="fas fa-trash me-1"></i>삭제
                                                            </button>
                                                            {% else %}
                                                            <button class="btn btn-sm btn-outline-secondary me-1" onclick="viewOperationEvaluation({{ rcm.rcm_id }}, '{{ session.design_evaluation_name }}')">
                                                                <i class="fas fa-eye me-1"></i>보기
                                                            </button>
                                                            <button class="btn btn-sm btn-outline-secondary" onclick="archiveEvaluation({{ session.header_id }}, '{{ session.evaluation_session }}')">
                                                                <i class="fas fa-archive me-1"></i>아카이브
                                                            </button>
                                                            {% endif %}
                                                        </td>
                                                    </tr>
                                                    {% endfor %}
                                                </tbody>
                                            </table>
                                        </div>

                                        <!-- 완료된 설계평가 중 운영평가 가능한 세션 표시 -->
                                        {% if rcm.design_sessions %}
                                        {% set startable_sessions = rcm.design_sessions|selectattr('status', 'equalto', 1)|list %}
                                        {% if startable_sessions %}
                                        <hr class="my-3">
                                        <h6 class="text-muted mb-3"><i class="fas fa-plus-circle me-1"></i>운영평가 시작 가능</h6>
                                        {% for session in startable_sessions %}
                                        {% if session.eligible_control_count > 0 %}
                                        <div class="card mb-2 border-primary">
                                            <div class="card-body py-2">
                                                <div class="d-flex justify-content-between align-items-center">
                                                    <div>
                                                        <strong>{{ session.evaluation_session }}</strong>
                                                        <span class="text-muted ms-2">({{ session.eligible_control_count }}개 통제)</span>
                                                    </div>
                                                    <div>
                                                        <button type="button" class="btn btn-primary btn-sm"
                                                                onclick="startOperationEvaluation({{ rcm.rcm_id }}, '{{ session.evaluation_session }}')">
                                                            <i class="fas fa-plus-circle me-1"></i>운영평가 시작
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        {% endif %}
                                        {% endfor %}
                                        {% endif %}
                                        {% endif %}
                                    </div>
                                </div>
                            </div>
                            {% endif %}
                            {% endfor %}
                        </div>
                        {% else %}
                        <div class="text-center py-4">
                            <i class="fas fa-hourglass-half fa-2x text-muted mb-2"></i>
                            <p class="text-muted">운영평가 세션이 없습니다.</p>
                            <small class="text-muted">설계평가가 완료된 후 운영평가를 시작할 수 있습니다.</small>
                        </div>
                        {% endif %}
                        {% else %}
                        <div class="text-center py-4">
                            <p class="text-muted">접근 가능한 RCM이 없습니다.</p>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 설계평가(내부평가) 시작 모달 -->
    <div class="modal fade" id="designEvaluationStartModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header bg-success text-white">
                    <h5 class="modal-title"><i class="fas fa-clipboard-check me-2"></i>내부평가 시작</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div id="rcmSelectionStep">
                        <p class="mb-3">평가할 RCM을 선택하세요.</p>
                        {% if rcms %}
                        <div class="list-group">
                            {% for rcm in rcms %}
                            <a href="#" class="list-group-item list-group-item-action" onclick="selectRcmForDesignEvaluation({{ rcm.rcm_id }}, '{{ rcm.rcm_name }}'); return false;">
                                <div class="d-flex w-100 justify-content-between align-items-center">
                                    <div>
                                        <h6 class="mb-1"><i class="fas fa-file-alt me-2"></i>{{ rcm.rcm_name }}</h6>
                                        <small class="text-muted">Control Category: {{ category }}</small>
                                    </div>
                                    {% if rcm.design_evaluation_completed %}
                                    <div>
                                        <span class="badge bg-success">완료된 세션 {{ rcm.completed_design_sessions|length }}개</span>
                                    </div>
                                    {% endif %}
                                </div>
                            </a>
                            {% endfor %}
                        </div>
                        {% else %}
                        <div class="text-center py-4">
                            <p class="text-muted">접근 가능한 {{ category }} RCM이 없습니다.</p>
                        </div>
                        {% endif %}
                    </div>

                    <div id="evaluationNameStep" style="display:none;">
                        <button type="button" class="btn btn-sm btn-outline-secondary mb-3" onclick="backToRcmSelection()">
                            <i class="fas fa-arrow-left me-1"></i>뒤로
                        </button>
                        <p class="mb-3"><strong id="selectedRcmName"></strong>의 설계평가를 시작합니다.</p>
                        <div class="mb-3">
                            <label for="evaluationNameInput" class="form-label">평가명 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="evaluationNameInput" placeholder="예: FY25_1차평가" required>
                            <small class="text-muted">평가 세션을 구분할 수 있는 이름을 입력하세요.</small>
                        </div>
                        <div class="row mb-3">
                            <div class="col-md-6">
                                <label for="evaluationPeriodStart" class="form-label">평가 대상 기간 시작일</label>
                                <input type="date" class="form-control" id="evaluationPeriodStart" placeholder="YYYY-MM-DD">
                                <small class="text-muted">예: 2025-01-01</small>
                            </div>
                            <div class="col-md-6">
                                <label for="evaluationPeriodEnd" class="form-label">평가 대상 기간 종료일</label>
                                <input type="date" class="form-control" id="evaluationPeriodEnd" placeholder="YYYY-MM-DD">
                                <small class="text-muted">예: 2025-12-31</small>
                            </div>
                        </div>
                        <div class="d-grid">
                            <button type="button" class="btn btn-success" onclick="startDesignEvaluationWithName()">
                                <i class="fas fa-play-circle me-1"></i>설계평가 시작
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 운영평가 시작 옵션 모달 -->
    <div class="modal fade" id="operationStartModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header bg-warning text-dark">
                    <h5 class="modal-title"><i class="fas fa-chart-line me-2"></i>운영평가 시작</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p class="mb-3"><strong id="modalSessionName"></strong> 세션의 운영평가를 시작합니다.</p>
                    <div id="existingSessionInfo" class="alert alert-info" style="display:none;">
                        <i class="fas fa-info-circle me-2"></i>
                        <span id="existingSessionText"></span>
                    </div>
                    <div class="d-grid gap-2">
                        <button type="button" class="btn btn-primary" id="continueExistingBtn" style="display:none;" onclick="continueExisting()">
                            <i class="fas fa-play-circle me-2"></i>기존 데이터로 계속하기
                        </button>
                        <button type="button" class="btn btn-success" onclick="startNew()">
                            <i class="fas fa-plus-circle me-2"></i>신규로 시작하기
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const CATEGORY = '{{ category }}';
        let currentRcmId, currentDesignSession;
        let selectedRcmIdForDesign, selectedRcmNameForDesign;

        // 토스트 메시지 표시 함수
        function showToast(message, type = 'success') {
            const toast = document.getElementById('successToast');
            const toastMessage = document.getElementById('toastMessage');

            // 타입에 따라 배경색 변경
            toast.classList.remove('text-bg-success', 'text-bg-danger', 'text-bg-warning', 'text-bg-info');
            toast.classList.add('text-bg-' + type);

            toastMessage.textContent = message;
            const bsToast = new bootstrap.Toast(toast, { delay: 3000 });
            bsToast.show();
        }

        // 설계평가(내부평가) 시작 모달 표시
        function showDesignEvaluationStartModal() {
            // 모달 리셋
            document.getElementById('rcmSelectionStep').style.display = 'block';
            document.getElementById('evaluationNameStep').style.display = 'none';
            document.getElementById('evaluationNameInput').value = '';

            const modal = new bootstrap.Modal(document.getElementById('designEvaluationStartModal'));
            modal.show();
        }

        // RCM 선택
        function selectRcmForDesignEvaluation(rcmId, rcmName) {
            selectedRcmIdForDesign = rcmId;
            selectedRcmNameForDesign = rcmName;

            // 다음 단계로 이동
            document.getElementById('rcmSelectionStep').style.display = 'none';
            document.getElementById('evaluationNameStep').style.display = 'block';
            document.getElementById('selectedRcmName').textContent = rcmName;

            // 입력 필드에 포커스
            document.getElementById('evaluationNameInput').focus();
        }

        // RCM 선택으로 돌아가기
        function backToRcmSelection() {
            document.getElementById('rcmSelectionStep').style.display = 'block';
            document.getElementById('evaluationNameStep').style.display = 'none';
            document.getElementById('evaluationNameInput').value = '';
        }

        // 평가명 입력 후 설계평가 시작
        function startDesignEvaluationWithName() {
            const evaluationName = document.getElementById('evaluationNameInput').value.trim();
            const periodStart = document.getElementById('evaluationPeriodStart').value;
            const periodEnd = document.getElementById('evaluationPeriodEnd').value;

            if (!evaluationName) {
                alert('평가명을 입력해주세요.');
                document.getElementById('evaluationNameInput').focus();
                return;
            }

            // 날짜 유효성 검사
            if (periodStart && periodEnd && periodStart > periodEnd) {
                alert('시작일이 종료일보다 늦을 수 없습니다.');
                document.getElementById('evaluationPeriodStart').focus();
                return;
            }

            // POST 요청으로 평가 세션 생성 및 설계평가 시작
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = `/${CATEGORY.toLowerCase()}/design-evaluation/start`;

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = selectedRcmIdForDesign;

            const nameInput = document.createElement('input');
            nameInput.type = 'hidden';
            nameInput.name = 'evaluation_name';
            nameInput.value = evaluationName;

            // 평가 기간 추가
            if (periodStart) {
                const startInput = document.createElement('input');
                startInput.type = 'hidden';
                startInput.name = 'evaluation_period_start';
                startInput.value = periodStart;
                form.appendChild(startInput);
            }

            if (periodEnd) {
                const endInput = document.createElement('input');
                endInput.type = 'hidden';
                endInput.name = 'evaluation_period_end';
                endInput.value = periodEnd;
                form.appendChild(endInput);
            }

            form.appendChild(rcmInput);
            form.appendChild(nameInput);
            document.body.appendChild(form);
            form.submit();
        }

        // 완료된 설계평가 보기 (읽기 전용)
        function viewDesignEvaluation(rcmId, evaluationSession) {
            console.log('[DEBUG] viewDesignEvaluation 호출됨:', rcmId, evaluationSession);
            // 읽기 전용 모드로 설계평가 페이지로 이동
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/design-evaluation/rcm';

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = rcmId;

            const sessionInput = document.createElement('input');
            sessionInput.type = 'hidden';
            sessionInput.name = 'session';
            sessionInput.value = evaluationSession;

            const typeInput = document.createElement('input');
            typeInput.type = 'hidden';
            typeInput.name = 'evaluation_type';
            typeInput.value = 'ITGC';

            const readonlyInput = document.createElement('input');
            readonlyInput.type = 'hidden';
            readonlyInput.name = 'readonly';
            readonlyInput.value = 'true';

            const csrfInput = document.createElement('input');
            csrfInput.type = 'hidden';
            csrfInput.name = 'csrf_token';
            csrfInput.value = '{{ csrf_token() }}';

            form.appendChild(rcmInput);
            form.appendChild(sessionInput);
            form.appendChild(typeInput);
            form.appendChild(readonlyInput);
            form.appendChild(csrfInput);
            document.body.appendChild(form);
            form.submit();
        }

        // 진행 중인 설계평가 계속하기
        function continueDesignEvaluation(rcmId, evaluationSession) {
            console.log('[DEBUG] continueDesignEvaluation 호출됨:', rcmId, evaluationSession);
            // 세션에 정보 저장하고 설계평가 페이지로 이동
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/design-evaluation/rcm';

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = rcmId;

            const sessionInput = document.createElement('input');
            sessionInput.type = 'hidden';
            sessionInput.name = 'session';
            sessionInput.value = evaluationSession;

            const typeInput = document.createElement('input');
            typeInput.type = 'hidden';
            typeInput.name = 'evaluation_type';
            typeInput.value = 'ITGC';

            const csrfInput = document.createElement('input');
            csrfInput.type = 'hidden';
            csrfInput.name = 'csrf_token';
            csrfInput.value = '{{ csrf_token() }}';

            form.appendChild(rcmInput);
            form.appendChild(sessionInput);
            form.appendChild(typeInput);
            form.appendChild(csrfInput);
            document.body.appendChild(form);
            form.submit();
        }

        // 진행 중인 운영평가 계속하기
        function continueOperationEvaluation(rcmId, evaluationName) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/operation-evaluation/rcm';

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = rcmId;

            const sessionInput = document.createElement('input');
            sessionInput.type = 'hidden';
            sessionInput.name = 'design_evaluation_session';
            sessionInput.value = evaluationName;

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

        // 완료된 운영평가 보기
        function viewOperationEvaluation(rcmId, evaluationName) {
            continueOperationEvaluation(rcmId, evaluationName);
        }

        // 운영평가 시작 (모달 없이 바로 이동)
        function startOperationEvaluation(rcmId, evaluationName) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/operation-evaluation/rcm';

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = rcmId;

            const sessionInput = document.createElement('input');
            sessionInput.type = 'hidden';
            sessionInput.name = 'design_evaluation_session';
            sessionInput.value = evaluationName;

            const actionInput = document.createElement('input');
            actionInput.type = 'hidden';
            actionInput.name = 'action';
            actionInput.value = 'start';

            form.appendChild(rcmInput);
            form.appendChild(sessionInput);
            form.appendChild(actionInput);
            document.body.appendChild(form);
            form.submit();
        }

        function showOperationStartModal(rcmId, designSession, operationCount, totalCount) {
            console.log('[DEBUG] showOperationStartModal 호출됨:', rcmId, designSession, operationCount, totalCount);
            currentRcmId = rcmId;
            currentDesignSession = designSession;

            document.getElementById('modalSessionName').textContent = designSession;

            if (operationCount > 0) {
                document.getElementById('existingSessionInfo').style.display = 'block';
                document.getElementById('existingSessionText').textContent =
                    `진행중인 운영평가가 있습니다 (${operationCount}/${totalCount})`;
                document.getElementById('continueExistingBtn').style.display = 'block';
            } else {
                document.getElementById('existingSessionInfo').style.display = 'none';
                document.getElementById('continueExistingBtn').style.display = 'none';
            }

            const modal = new bootstrap.Modal(document.getElementById('operationStartModal'));
            modal.show();
        }

        function continueDirectly(rcmId, designSession) {
            console.log('[DEBUG] continueDirectly 호출됨:', rcmId, designSession);
            // 모달 없이 바로 기존 데이터로 이동
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/operation-evaluation/rcm';

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = rcmId;

            const sessionInput = document.createElement('input');
            sessionInput.type = 'hidden';
            sessionInput.name = 'design_evaluation_session';
            sessionInput.value = designSession;

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

        function continueExisting() {
            console.log('[DEBUG] continueExisting 호출됨');
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/operation-evaluation/rcm';

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = currentRcmId;

            const sessionInput = document.createElement('input');
            sessionInput.type = 'hidden';
            sessionInput.name = 'design_evaluation_session';
            sessionInput.value = currentDesignSession;

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

        function startNew() {
            console.log('[DEBUG] startNew 호출됨');
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/operation-evaluation/rcm';

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = currentRcmId;

            const sessionInput = document.createElement('input');
            sessionInput.type = 'hidden';
            sessionInput.name = 'design_evaluation_session';
            sessionInput.value = currentDesignSession;

            const actionInput = document.createElement('input');
            actionInput.type = 'hidden';
            actionInput.name = 'action';
            actionInput.value = 'start_new';

            form.appendChild(rcmInput);
            form.appendChild(sessionInput);
            form.appendChild(actionInput);
            document.body.appendChild(form);
            form.submit();
        }

        // 완료된 운영평가 보기 (읽기 전용)
        function viewOperationEvaluation(rcmId, designEvaluationName) {
            console.log('[DEBUG] viewOperationEvaluation 호출됨:', rcmId, designEvaluationName);
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = '/operation-evaluation/rcm';

            const rcmInput = document.createElement('input');
            rcmInput.type = 'hidden';
            rcmInput.name = 'rcm_id';
            rcmInput.value = rcmId;

            const sessionInput = document.createElement('input');
            sessionInput.type = 'hidden';
            sessionInput.name = 'design_evaluation_session';
            sessionInput.value = designEvaluationName;

            const readonlyInput = document.createElement('input');
            readonlyInput.type = 'hidden';
            readonlyInput.name = 'readonly';
            readonlyInput.value = 'true';

            form.appendChild(rcmInput);
            form.appendChild(sessionInput);
            form.appendChild(readonlyInput);
            document.body.appendChild(form);
            form.submit();
        }

        // 평가 아카이브
        function archiveEvaluation(headerId, evaluationName) {
            if (!confirm(`"${evaluationName}" 평가를 아카이브하시겠습니까?

아카이브된 평가는 별도 메뉴에서 확인할 수 있습니다.`)) {
                return;
            }

            fetch('/itgc/evaluation/archive', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    header_id: headerId
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('평가가 아카이브되었습니다.');
                    location.reload();
                } else {
                    alert('아카이브 실패: ' + (data.error || '알 수 없는 오류'));
                }
            })
            .catch(error => {
                alert('아카이브 중 오류가 발생했습니다: ' + error);
            });
        }

        // 평가 삭제
        function deleteEvaluation(headerId, evaluationName) {
            if (!confirm(`"${evaluationName}" 평가를 삭제하시겠습니까?\n\n삭제된 평가 데이터는 복구할 수 없습니다.`)) {
                return;
            }

            fetch('/itgc/evaluation/delete', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    header_id: headerId
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showToast('평가가 삭제되었습니다.', 'success');
                    setTimeout(() => location.reload(), 1500);
                } else {
                    showToast('삭제 실패: ' + (data.error || '알 수 없는 오류'), 'danger');
                }
            })
            .catch(error => {
                showToast('삭제 중 오류가 발생했습니다: ' + error, 'danger');
            });
        }

        // 페이지 로드 시 세션에서 선택된 RCM 자동 확장
        document.addEventListener('DOMContentLoaded', function() {
            {% if current_rcm_id %}
            const rcmId = {{ current_rcm_id }};
            const collapseElement = document.getElementById('collapse' + rcmId);
            const opCollapseElement = document.getElementById('opcollapse' + rcmId);

            if (collapseElement) {
                const bsCollapse = new bootstrap.Collapse(collapseElement, {toggle: true});
                // 스크롤하여 해당 RCM으로 이동
                setTimeout(function() {
                    collapseElement.scrollIntoView({behavior: 'smooth', block: 'center'});
                }, 300);
            }

            if (opCollapseElement) {
                const bsOpCollapse = new bootstrap.Collapse(opCollapseElement, {toggle: true});
            }
            {% endif %}

            {% if start_design_rcm_id and start_design_rcm_name %}
            // URL 파라미터로 전달된 RCM으로 설계평가 시작 모달 자동 표시
            setTimeout(function() {
                selectRcmForDesign({{ start_design_rcm_id }}, '{{ start_design_rcm_name }}');
                const modal = new bootstrap.Modal(document.getElementById('designEvaluationStartModal'));
                modal.show();
            }, 500);
            {% endif %}
        });
    </script>
</body>
</html>
