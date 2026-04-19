<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - {{ evaluation_type|default('ITGC') }} 운영평가</title>
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

    {% set eval_type = evaluation_type|default('ITGC') %}
    {% set eval_image = 'itgc.jpg' if eval_type == 'ITGC' else ('elc.jpg' if eval_type == 'ELC' else 'tlc.jpg') %}

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h1><img src="{{ url_for('static', filename='img/' ~ eval_image) }}" alt="{{ eval_type }}" style="width: 40px; height: 40px; object-fit: cover; border-radius: 8px; margin-right: 12px;">{{ eval_type }} 운영평가</h1>
                    <a href="/" class="btn btn-secondary">
                        <i class="fas fa-home me-1"></i>홈으로
                    </a>
                </div>
                <hr>
            </div>
        </div>

        <!-- 운영평가 소개 -->
        <div class="row mb-4">
            <div class="col-12">
                <div class="card border-warning">
                    <div class="card-header bg-warning text-dark">
                        <h5><i class="fas fa-info-circle me-2"></i>운영평가란?</h5>
                    </div>
                    <div class="card-body">
                        <p class="card-text">
                            <strong>운영평가(Operating Effectiveness Testing)</strong>는 설계평가가 완료된 통제가 실제로 의도된 대로 작동하고 있는지를 평가하는 과정입니다.
                        </p>
                        <ul>
                            <li><strong>전제조건:</strong> 설계평가가 완료되어 통제 설계가 적정하다고 평가된 통제만 대상</li>
                            <li><strong>목적:</strong> 통제가 일정 기간 동안 일관되게 효과적으로 운영되고 있는지 검증</li>
                            <li><strong>범위:</strong> 통제의 실행, 모니터링, 예외 처리 등 운영 현황 전반</li>
                            <li><strong>결과:</strong> 운영 효과성 결론 및 운영상 개선점 도출</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>

        <!-- 2. 설계평가 현황 -->
        <div class="row mb-4">
            <div class="col-12">
                <div class="card">
                    <div class="card-header bg-light">
                        <h5 class="mb-0"><i class="fas fa-clipboard-check me-2"></i>설계평가 현황</h5>
                    </div>
                    <div class="card-body">
                        {% if user_rcms %}
                        {% set has_any_sessions = user_rcms|selectattr('all_design_sessions')|list|length > 0 %}
                        {% if has_any_sessions %}
                        <div class="accordion" id="designEvaluationAccordion">
                            {% for rcm in user_rcms %}
                            {% if rcm.all_design_sessions|length > 0 %}
                            <div class="accordion-item">
                                <h2 class="accordion-header" id="heading{{ rcm.rcm_id }}">
                                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapse{{ rcm.rcm_id }}">
                                        <i class="fas fa-file-alt me-2"></i>{{ rcm.rcm_name }}
                                        {% if rcm.in_progress_design_sessions|length > 0 %}
                                        <span class="badge bg-warning text-dark ms-2">진행중 {{ rcm.in_progress_design_sessions|length }}개</span>
                                        {% endif %}
                                        {% if rcm.completed_design_sessions|length > 0 %}
                                        <span class="badge bg-success ms-2">완료 {{ rcm.completed_design_sessions|length }}개</span>
                                        {% endif %}
                                    </button>
                                </h2>
                                <div id="collapse{{ rcm.rcm_id }}" class="accordion-collapse collapse" data-bs-parent="#designEvaluationAccordion">
                                    <div class="accordion-body">
                                        {% if rcm.in_progress_design_sessions|length > 0 %}
                                        <h6 class="text-warning mb-3"><i class="fas fa-hourglass-half me-2"></i>진행 중인 설계평가</h6>
                                        <div class="table-responsive mb-4">
                                            <table class="table table-sm table-bordered">
                                                <thead class="table-warning">
                                                    <tr>
                                                        <th>세션명</th>
                                                        <th>시작일</th>
                                                        <th>진행률</th>
                                                        <th>상태</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    {% for session in rcm.in_progress_design_sessions %}
                                                    <tr>
                                                        <td>
                                                            <i class="fas fa-spinner text-warning me-1"></i>
                                                            <a href="/design-evaluation/rcm?rcm_id={{ rcm.rcm_id }}&session={{ session.evaluation_session }}"
                                                               class="text-decoration-none"
                                                               title="설계평가 진행 화면으로 이동">
                                                                {{ session.evaluation_session }}
                                                            </a>
                                                        </td>
                                                        <td>{{ session.start_date[:10] if session.start_date else '-' }}</td>
                                                        <td>
                                                            <div class="d-flex align-items-center">
                                                                <div class="progress flex-grow-1 me-2" style="height: 20px;">
                                                                    <div class="progress-bar bg-warning" role="progressbar" style="width: {{ session.progress_percentage|default(0) }}%">
                                                                        {{ session.progress_percentage|default(0)|round(1) }}%
                                                                    </div>
                                                                </div>
                                                                <small class="text-muted text-nowrap">
                                                                    <strong>{{ session.evaluated_controls|default(0) }}/{{ session.total_controls|default(0) }}</strong>
                                                                </small>
                                                            </div>
                                                        </td>
                                                        <td><span class="badge bg-warning text-dark">진행중</span></td>
                                                    </tr>
                                                    {% endfor %}
                                                </tbody>
                                            </table>
                                        </div>
                                        {% endif %}

                                        {% if rcm.completed_design_sessions|length > 0 %}
                                        <h6 class="text-success mb-3"><i class="fas fa-check-circle me-2"></i>완료된 설계평가</h6>
                                        <div class="table-responsive">
                                            <table class="table table-sm table-bordered">
                                                <thead class="table-success">
                                                    <tr>
                                                        <th>세션명</th>
                                                        <th>완료일</th>
                                                        <th>평가 대상 통제</th>
                                                        <th>상태</th>
                                                        <th>작업</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    {% for session in rcm.completed_design_sessions %}
                                                    <tr>
                                                        <td>
                                                            <i class="fas fa-check-circle text-success me-1"></i>
                                                            <a href="/design-evaluation/rcm?rcm_id={{ rcm.rcm_id }}&session={{ session.evaluation_session }}"
                                                               class="text-decoration-none"
                                                               title="설계평가 결과 조회">
                                                                {{ session.evaluation_session }}
                                                            </a>
                                                        </td>
                                                        <td>{{ session.completed_date[:10] if session.completed_date else '-' }}</td>
                                                        <td>{{ session.eligible_control_count }}개</td>
                                                        <td>
                                                            {% if session.eligible_control_count > 0 %}
                                                            <span class="badge bg-success">운영평가 가능</span>
                                                            {% else %}
                                                            <span class="badge bg-secondary">적정 통제 없음</span>
                                                            {% endif %}
                                                        </td>
                                                        <td>
                                                            {% if session.eligible_control_count > 0 %}
                                                            <button class="btn btn-sm btn-success"
                                                                    onclick="window.location.href='/design-evaluation/rcm?rcm_id={{ rcm.rcm_id }}&session={{ session.evaluation_session }}'">
                                                                <i class="fas fa-eye me-1"></i>설계평가 보기
                                                            </button>
                                                            {% else %}
                                                            -
                                                            {% endif %}
                                                        </td>
                                                    </tr>
                                                    {% endfor %}
                                                </tbody>
                                            </table>
                                        </div>
                                        {% endif %}
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
                            <small class="text-muted">설계평가를 시작해주세요.</small>
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

        <!-- 3. 운영평가 현황 -->
        <div class="row mb-4">
            <div class="col-12">
                <div class="card">
                    <div class="card-header bg-light">
                        <h5 class="mb-0"><i class="fas fa-chart-line me-2"></i>운영평가 현황</h5>
                    </div>
                    <div class="card-body">
                        {% if user_rcms %}
                        {% set has_operation_sessions = user_rcms|selectattr('design_evaluation_completed')|list|length > 0 %}
                        {% if has_operation_sessions %}
                        <div class="accordion" id="operationEvaluationAccordion">
                            {% for rcm in user_rcms %}
                            {% if rcm.design_evaluation_completed %}
                            <div class="accordion-item">
                                <h2 class="accordion-header" id="opheading{{ rcm.rcm_id }}">
                                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#opcollapse{{ rcm.rcm_id }}">
                                        <i class="fas fa-file-alt me-2"></i>{{ rcm.rcm_name }}
                                        {% set in_progress = rcm.completed_design_sessions|selectattr('operation_completed_count', 'gt', 0)|list|length %}
                                        {% if in_progress > 0 %}
                                        <span class="badge bg-warning text-dark ms-2">진행중 {{ in_progress }}개</span>
                                        {% else %}
                                        <span class="badge bg-secondary ms-2">진행중 없음</span>
                                        {% endif %}
                                    </button>
                                </h2>
                                <div id="opcollapse{{ rcm.rcm_id }}" class="accordion-collapse collapse" data-bs-parent="#operationEvaluationAccordion">
                                    <div class="accordion-body">
                                        {% for session in rcm.completed_design_sessions %}
                                        <div class="card mb-3">
                                            <div class="card-header {% if session.operation_completed_count > 0 %}bg-warning bg-opacity-10{% endif %}">
                                                <strong>{{ session.evaluation_session }}</strong>
                                                <span class="text-muted ms-2">(설계평가 완료: {{ session.completed_date[:10] if session.completed_date else '-' }})</span>
                                            </div>
                                            <div class="card-body">
                                                {% if session.eligible_control_count > 0 %}
                                                <div class="d-flex justify-content-between align-items-center mb-2">
                                                    <div>
                                                        <span class="text-muted">진행상황:</span>
                                                        <strong>{{ session.operation_completed_count }}/{{ session.eligible_control_count }}</strong> 통제
                                                    </div>
                                                    <button type="button" class="btn btn-warning btn-sm"
                                                            onclick="continueDirectly({{ rcm.rcm_id }}, '{{ session.evaluation_session }}')">
                                                        <i class="fas fa-eye me-1"></i>운영평가 보기
                                                    </button>
                                                </div>
                                                {% if session.operation_completed_count > 0 %}
                                                <div class="progress" style="height: 20px;">
                                                    <div class="progress-bar bg-warning" role="progressbar"
                                                         style="width: {{ (session.operation_completed_count / session.eligible_control_count * 100)|round(1) }}%">
                                                        {{ (session.operation_completed_count / session.eligible_control_count * 100)|round(1) }}%
                                                    </div>
                                                </div>
                                                {% endif %}
                                                {% else %}
                                                <p class="text-muted mb-0">
                                                    <i class="fas fa-exclamation-triangle me-1"></i>설계평가 '적정' 통제가 없어 운영평가를 진행할 수 없습니다.
                                                </p>
                                                {% endif %}
                                            </div>
                                        </div>
                                        {% endfor %}
                                    </div>
                                </div>
                            </div>
                            {% endif %}
                            {% endfor %}
                        </div>
                        {% else %}
                        <div class="text-center py-4">
                            <i class="fas fa-hourglass-half fa-2x text-muted mb-2"></i>
                            <p class="text-muted">설계평가를 먼저 완료해주세요.</p>
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
                        <button type="button" class="btn btn-primary w-100" id="continueExistingBtn" style="display:none;" onclick="continueExisting()">
                            <i class="fas fa-play-circle me-2"></i>기존 데이터로 계속하기
                        </button>
                        <button type="button" class="btn btn-success w-100" onclick="startNew()">
                            <i class="fas fa-plus-circle me-2"></i>신규로 시작하기
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        let currentRcmId, currentDesignSession, currentOperationCount;

        function showOperationStartModal(rcmId, designSession, operationCount, totalCount) {
            console.log('[DEBUG] showOperationStartModal 호출됨:', rcmId, designSession, operationCount, totalCount);
            currentRcmId = rcmId;
            currentDesignSession = designSession;
            currentOperationCount = operationCount || 0;

            document.getElementById('modalSessionName').textContent = designSession;

            if (currentOperationCount > 0) {
                document.getElementById('existingSessionInfo').style.display = 'block';
                document.getElementById('existingSessionText').textContent =
                    `진행중인 운영평가가 있습니다 (${currentOperationCount}/${totalCount})`;
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
            // 모달에서 '기존 데이터로 계속하기' 클릭 시
            continueDirectly(currentRcmId, currentDesignSession);
        }

        function startNew() {
            // 기존 진행 데이터가 있는 경우에만 확인 메시지 표시
            if (currentOperationCount > 0) {
                if (!confirm('새로운 운영평가를 시작하면 기존 진행 데이터가 삭제됩니다. 계속하시겠습니까?')) {
                    return;
                }
            }

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
            actionInput.value = 'new';

            form.appendChild(rcmInput);
            form.appendChild(sessionInput);
            form.appendChild(actionInput);
            document.body.appendChild(form);
            form.submit();
        }

        // 페이지 로드 시 세션에서 선택된 RCM 자동 확장
        document.addEventListener('DOMContentLoaded', function() {
            {% if current_rcm_id %}
            const rcmId = {{ current_rcm_id }};
            const collapseElement = document.getElementById('collapse' + rcmId);

            if (collapseElement) {
                const bsCollapse = new bootstrap.Collapse(collapseElement, {toggle: true});
                // 스크롤하여 해당 RCM으로 이동
                setTimeout(function() {
                    collapseElement.scrollIntoView({behavior: 'smooth', block: 'center'});
                }, 300);
            }
            {% endif %}
        });
    </script>
</body>
</html>
