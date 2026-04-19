<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - Dashboard</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .category-card {
            border-width: 2px !important;
        }
        .category-card .card-body {
            display: flex;
            flex-direction: column;
            /* 카드 높이를 약간 줄여 불필요한 여백 최소화 */
            min-height: 340px;
        }
        .category-card .d-grid {
            /* 버튼을 카드 맨 아래까지 내리지 않고 인디케이터와 간격을 줄임 */
            margin-top: 0.75rem;
        }
        .progress-ring {
            width: 50px;
            height: 50px;
        }
        .progress-ring-bg {
            fill: transparent;
            stroke: #e9ecef;
            stroke-width: 8;
        }
        .progress-ring-fill {
            fill: transparent;
            stroke: #28a745;
            stroke-width: 8;
            stroke-linecap: round;
            transition: stroke-dasharray 0.5s ease-in-out;
            transform: rotate(-90deg);
            transform-origin: 50% 50%;
        }
        .step-indicator {
            display: flex;
            justify-content: space-between;
            margin-bottom: 0 !important;
            position: relative;
        }
        .step-item {
            flex: 1;
            text-align: center;
            position: relative;
            margin-bottom: 0.5rem;
        }
        .step-number {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 0.25rem;
            font-weight: bold;
            position: relative;
            z-index: 2;
            font-size: 1rem;
        }
        .step-item.completed .step-number {
            background-color: #28a745;
            color: white;
        }
        .step-item.in-progress .step-number {
            background-color: #007bff;
            color: white;
        }
        .step-item.pending .step-number {
            background-color: #e9ecef;
            color: #6c757d;
            border: 2px solid #adb5bd;
        }
        .step-connector {
            position: absolute;
            top: 18px;
            left: 50%;
            right: -50%;
            height: 3px;
            background-color: #dee2e6;
            z-index: 1;
        }
        .step-item:last-child .step-connector {
            display: none;
        }
        .step-item.completed .step-connector {
            background-color: #28a745;
        }
    </style>
</head>
<body>
    {% include 'navi.jsp' %}

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <div class="mb-4">
                    <h1><i class="fas fa-tasks me-2 text-primary"></i>Dashboard</h1>
                </div>
                <p class="text-muted mb-4">
                    RCM의 단계별 내부평가를 진행하여 통제 설계와 운영 효과성을 체계적으로 검토할 수 있습니다.
                </p>
            </div>
        </div>

        <!-- 회사별 내부평가 현황 -->
        {% if companies %}
            {% for company in companies %}
            <div class="mb-5">
                <!-- 회사명 헤더 -->
                <div class="mb-3 pb-2 border-bottom border-primary">
                    <h3><i class="fas fa-building me-2 text-primary"></i>{{ company.company_name }}</h3>
                </div>

                <!-- 3개 카테고리를 가로로 배치: ELC → TLC → ITGC -->
                <div class="row g-3">
                    <!-- ELC 카드 -->
                    <div class="col-md-4">
                        <div class="card category-card border-warning">
                            <div class="card-header bg-warning text-dark">
                                <h6 class="mb-0"><i class="fas fa-building me-2"></i>전사 수준 통제 (ELC)</h6>
                            </div>
                            <div class="card-body">
                                {% if company.categories.ELC %}
                                    {% set item = company.categories.ELC[0] %}
                                    <!-- RCM 정보 -->
                                    <h6 class="mb-2">{{ item.rcm_info.rcm_name }}</h6>
                                    <div class="d-flex justify-content-between align-items-center mb-3">
                                        <div>
                                            <small class="text-muted d-block">세션: {{ item.evaluation_session }}</small>
                                            {% if item.evaluation_status == 'COMPLETED' and item.operation_status == 'COMPLETED' %}
                                            <span class="badge bg-success">완료</span>
                                            {% elif item.evaluation_status == 'IN_PROGRESS' or item.operation_status == 'IN_PROGRESS' %}
                                            <span class="badge bg-primary">진행중</span>
                                            {% else %}
                                            <span class="badge bg-secondary">대기</span>
                                            {% endif %}
                                        </div>
                                        <div class="text-center">
                                            <svg class="progress-ring" viewBox="0 0 100 100">
                                                <circle class="progress-ring-bg" cx="50" cy="50" r="42"></circle>
                                                <circle class="progress-ring-fill" cx="50" cy="50" r="42"
                                                        style="stroke-dasharray: {{ (item.progress.overall_progress * 264) / 100 }} 264"></circle>
                                            </svg>
                                            <div style="font-size: 0.8rem; margin-top: -8px;">
                                                <strong class="text-primary">{{ item.progress.overall_progress }}%</strong>
                                            </div>
                                        </div>
                                    </div>
                                    <!-- 단계 인디케이터 -->
                                    <div class="step-indicator">
                                        {% for step in item.progress.steps %}
                                        <div class="step-item {{ step.status }}">
                                            <div class="step-number">
                                                {% if step.status == 'completed' %}<i class="fas fa-check"></i>
                                                {% elif step.status == 'in-progress' %}<i class="fas fa-play"></i>
                                                {% else %}<i class="fas fa-circle"></i>
                                                {% endif %}
                                            </div>
                                            <div class="step-connector"></div>
                                            <small class="text-muted" style="font-size: 0.85rem; font-weight: 500;">{{ step.name[:2] }}</small>
                                        </div>
                                        {% endfor %}
                                    </div>
                                    <div class="mb-3">
                                        <a href="{{ url_for('link8.link8_detail', rcm_id=item.rcm_info.rcm_id, evaluation_session=item.evaluation_session) }}" class="btn btn-sm btn-outline-primary w-100">
                                            <i class="fas fa-info-circle"></i> 상세 현황 보기
                                        </a>
                                    </div>
                                    <!-- 버튼 (ELC용) -->
                                    <div class="d-grid gap-2">
                                        {% if item.progress.steps[0].status == 'completed' %}
                                        <form action="/user/design-evaluation" method="POST" style="display: inline;">
                                            <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                            <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                            <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                            <button type="submit" class="btn btn-sm btn-outline-success w-100">
                                                <i class="fas fa-check-circle"></i> 설계평가 확인
                                            </button>
                                        </form>
                                        {% elif item.progress.steps[0].status == 'in-progress' %}
                                        <form action="/user/design-evaluation" method="POST" style="display: inline;">
                                            <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                            <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                            <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                            <button type="submit" class="btn btn-sm btn-primary w-100">
                                                <i class="fas fa-clipboard-check"></i> 설계평가 계속
                                            </button>
                                        </form>
                                        {% else %}
                                        <a href="{{ url_for('link6.elc_design_evaluation') }}" class="btn btn-sm btn-info w-100">
                                            <i class="fas fa-play"></i> 설계평가 시작
                                        </a>
                                        {% endif %}

                                        {% if item.progress.steps[0].status == 'completed' %}
                                            {% if item.progress.steps[1].status == 'completed' %}
                                            <form action="/user/operation-evaluation" method="POST" style="display: inline;">
                                                <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                                <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                                <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                                <button type="submit" class="btn btn-sm btn-outline-success w-100">
                                                    <i class="fas fa-check-circle"></i> 운영평가 확인
                                                </button>
                                            </form>
                                            {% elif item.progress.steps[1].status == 'in-progress' %}
                                            <form action="/user/operation-evaluation" method="POST" style="display: inline;">
                                                <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                                <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                                <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                                <button type="submit" class="btn btn-sm btn-success w-100">
                                                    <i class="fas fa-cogs"></i> 운영평가 계속
                                                </button>
                                            </form>
                                            {% else %}
                                            <a href="{{ url_for('link7.elc_operation_evaluation') }}" class="btn btn-sm btn-warning w-100">
                                                <i class="fas fa-play"></i> 운영평가 시작
                                            </a>
                                            {% endif %}
                                        {% else %}
                                        <div data-bs-toggle="tooltip" data-bs-placement="top"
                                             title="설계평가를 먼저 완료해주세요">
                                            <button class="btn btn-sm btn-outline-secondary w-100" disabled style="pointer-events: none;">
                                                <i class="fas fa-lock"></i> 운영평가 (잠김)
                                            </button>
                                        </div>
                                        {% endif %}
                                    </div>
                                {% else %}
                                    <div class="text-center text-muted py-5">
                                        <i class="fas fa-inbox fa-3x mb-3"></i>
                                        <p class="mb-0">ELC RCM이 없습니다</p>
                                    </div>
                                {% endif %}
                            </div>
                        </div>
                    </div>

                    <!-- TLC 카드 -->
                    <div class="col-md-4">
                        <div class="card category-card border-success">
                            <div class="card-header bg-success text-white">
                                <h6 class="mb-0"><i class="fas fa-exchange-alt me-2"></i>거래 수준 통제 (TLC)</h6>
                            </div>
                            <div class="card-body">
                                {% if company.categories.TLC %}
                                    {% set item = company.categories.TLC[0] %}
                                    <!-- RCM 정보 -->
                                    <h6 class="mb-2">{{ item.rcm_info.rcm_name }}</h6>
                                    <div class="d-flex justify-content-between align-items-center mb-3">
                                        <div>
                                            <small class="text-muted d-block">세션: {{ item.evaluation_session }}</small>
                                            {% if item.evaluation_status == 'COMPLETED' and item.operation_status == 'COMPLETED' %}
                                            <span class="badge bg-success">완료</span>
                                            {% elif item.evaluation_status == 'IN_PROGRESS' or item.operation_status == 'IN_PROGRESS' %}
                                            <span class="badge bg-primary">진행중</span>
                                            {% else %}
                                            <span class="badge bg-secondary">대기</span>
                                            {% endif %}
                                        </div>
                                        <div class="text-center">
                                            <svg class="progress-ring" viewBox="0 0 100 100">
                                                <circle class="progress-ring-bg" cx="50" cy="50" r="42"></circle>
                                                <circle class="progress-ring-fill" cx="50" cy="50" r="42"
                                                        style="stroke-dasharray: {{ (item.progress.overall_progress * 264) / 100 }} 264"></circle>
                                            </svg>
                                            <div style="font-size: 0.8rem; margin-top: -8px;">
                                                <strong class="text-primary">{{ item.progress.overall_progress }}%</strong>
                                            </div>
                                        </div>
                                    </div>
                                    <!-- 단계 인디케이터 -->
                                    <div class="step-indicator">
                                        {% for step in item.progress.steps %}
                                        <div class="step-item {{ step.status }}">
                                            <div class="step-number">
                                                {% if step.status == 'completed' %}<i class="fas fa-check"></i>
                                                {% elif step.status == 'in-progress' %}<i class="fas fa-play"></i>
                                                {% else %}<i class="fas fa-circle"></i>
                                                {% endif %}
                                            </div>
                                            <div class="step-connector"></div>
                                            <small class="text-muted" style="font-size: 0.85rem; font-weight: 500;">{{ step.name[:2] }}</small>
                                        </div>
                                        {% endfor %}
                                    </div>
                                    <div class="mb-3">
                                        <a href="{{ url_for('link8.link8_detail', rcm_id=item.rcm_info.rcm_id, evaluation_session=item.evaluation_session) }}" class="btn btn-sm btn-outline-primary w-100">
                                            <i class="fas fa-info-circle"></i> 상세 현황 보기
                                        </a>
                                    </div>
                                    <!-- 버튼 (TLC용) -->
                                    <div class="d-grid gap-2">
                                        {% if item.progress.steps[0].status == 'completed' %}
                                        <form action="/user/design-evaluation" method="POST" style="display: inline;">
                                            <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                            <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                            <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                            <button type="submit" class="btn btn-sm btn-outline-success w-100">
                                                <i class="fas fa-check-circle"></i> 설계평가 확인
                                            </button>
                                        </form>
                                        {% elif item.progress.steps[0].status == 'in-progress' %}
                                        <form action="/user/design-evaluation" method="POST" style="display: inline;">
                                            <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                            <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                            <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                            <button type="submit" class="btn btn-sm btn-primary w-100">
                                                <i class="fas fa-clipboard-check"></i> 설계평가 계속
                                            </button>
                                        </form>
                                        {% else %}
                                        <a href="{{ url_for('link6.tlc_design_evaluation') }}" class="btn btn-sm btn-info w-100">
                                            <i class="fas fa-play"></i> 설계평가 시작
                                        </a>
                                        {% endif %}

                                        {% if item.progress.steps[0].status == 'completed' %}
                                            {% if item.progress.steps[1].status == 'completed' %}
                                            <form action="/user/operation-evaluation" method="POST" style="display: inline;">
                                                <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                                <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                                <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                                <button type="submit" class="btn btn-sm btn-outline-success w-100">
                                                    <i class="fas fa-check-circle"></i> 운영평가 확인
                                                </button>
                                            </form>
                                            {% elif item.progress.steps[1].status == 'in-progress' %}
                                            <form action="/user/operation-evaluation" method="POST" style="display: inline;">
                                                <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                                <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                                <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                                <button type="submit" class="btn btn-sm btn-success w-100">
                                                    <i class="fas fa-cogs"></i> 운영평가 계속
                                                </button>
                                            </form>
                                            {% else %}
                                            <a href="{{ url_for('link7.tlc_operation_evaluation') }}" class="btn btn-sm btn-warning w-100">
                                                <i class="fas fa-play"></i> 운영평가 시작
                                            </a>
                                            {% endif %}
                                        {% else %}
                                        <div data-bs-toggle="tooltip" data-bs-placement="top"
                                             title="설계평가를 먼저 완료해주세요">
                                            <button class="btn btn-sm btn-outline-secondary w-100" disabled style="pointer-events: none;">
                                                <i class="fas fa-lock"></i> 운영평가 (잠김)
                                            </button>
                                        </div>
                                        {% endif %}
                                    </div>
                                {% else %}
                                    <div class="text-center text-muted py-5">
                                        <i class="fas fa-inbox fa-3x mb-3"></i>
                                        <p class="mb-0">TLC RCM이 없습니다</p>
                                    </div>
                                {% endif %}
                            </div>
                        </div>
                    </div>

                    <!-- ITGC 카드 (3번째) -->
                    <div class="col-md-4">
                        <div class="card category-card border-info">
                            <div class="card-header bg-info text-white">
                                <h6 class="mb-0"><i class="fas fa-server me-2"></i>IT 일반 통제 (ITGC)</h6>
                            </div>
                            <div class="card-body">
                                {% if company.categories.ITGC %}
                                    {% set item = company.categories.ITGC[0] %}
                                    <h6 class="mb-2">{{ item.rcm_info.rcm_name }}</h6>
                                    <div class="d-flex justify-content-between align-items-center mb-3">
                                        <div>
                                            <small class="text-muted d-block">세션: {{ item.evaluation_session }}</small>
                                            {% if item.evaluation_status == 'COMPLETED' and item.operation_status == 'COMPLETED' %}
                                            <span class="badge bg-success">완료</span>
                                            {% elif item.evaluation_status == 'IN_PROGRESS' or item.operation_status == 'IN_PROGRESS' %}
                                            <span class="badge bg-primary">진행중</span>
                                            {% else %}
                                            <span class="badge bg-secondary">대기</span>
                                            {% endif %}
                                        </div>
                                        <div class="text-center">
                                            <svg class="progress-ring" viewBox="0 0 100 100">
                                                <circle class="progress-ring-bg" cx="50" cy="50" r="42"></circle>
                                                <circle class="progress-ring-fill" cx="50" cy="50" r="42"
                                                        style="stroke-dasharray: {{ (item.progress.overall_progress * 264) / 100 }} 264"></circle>
                                            </svg>
                                            <div style="font-size: 0.8rem; margin-top: -8px;">
                                                <strong class="text-primary">{{ item.progress.overall_progress }}%</strong>
                                            </div>
                                        </div>
                                    </div>
                                    <!-- 단계 인디케이터 -->
                                    <div class="step-indicator">
                                        {% for step in item.progress.steps %}
                                        <div class="step-item {{ step.status }}">
                                            <div class="step-number">
                                                {% if step.status == 'completed' %}<i class="fas fa-check"></i>
                                                {% elif step.status == 'in-progress' %}<i class="fas fa-play"></i>
                                                {% else %}<i class="fas fa-circle"></i>
                                                {% endif %}
                                            </div>
                                            <div class="step-connector"></div>
                                            <small class="text-muted" style="font-size: 0.85rem; font-weight: 500;">{{ step.name[:2] }}</small>
                                        </div>
                                        {% endfor %}
                                    </div>
                                    <div class="mb-3">
                                        <a href="{{ url_for('link8.link8_detail', rcm_id=item.rcm_info.rcm_id, evaluation_session=item.evaluation_session) }}" class="btn btn-sm btn-outline-primary w-100">
                                            <i class="fas fa-info-circle"></i> 상세 현황 보기
                                        </a>
                                    </div>
                                    <!-- 버튼 -->
                                    <div class="d-grid gap-2">
                                        {% if item.progress.steps[0].status == 'completed' %}
                                        <form action="/user/design-evaluation" method="POST" style="display: inline;">
                                            <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                            <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                            <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                            <button type="submit" class="btn btn-sm btn-outline-success w-100">
                                                <i class="fas fa-check-circle"></i> 설계평가 확인
                                            </button>
                                        </form>
                                        {% elif item.progress.steps[0].status == 'in-progress' %}
                                        <form action="/user/design-evaluation" method="POST" style="display: inline;">
                                            <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                            <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                            <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                            <button type="submit" class="btn btn-sm btn-primary w-100">
                                                <i class="fas fa-clipboard-check"></i> 설계평가 계속
                                            </button>
                                        </form>
                                        {% else %}
                                        <a href="{{ url_for('link6.itgc_evaluation') }}" class="btn btn-sm btn-info w-100">
                                            <i class="fas fa-play"></i> 설계평가 시작
                                        </a>
                                        {% endif %}
                                        {% if item.progress.steps[0].status == 'completed' %}
                                            {% if item.progress.steps[1].status == 'completed' %}
                                            <form action="/user/operation-evaluation" method="POST" style="display: inline;">
                                                <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                                <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                                <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                                <button type="submit" class="btn btn-sm btn-outline-success w-100">
                                                    <i class="fas fa-check-circle"></i> 운영평가 확인
                                                </button>
                                            </form>
                                            {% elif item.progress.steps[1].status == 'in-progress' %}
                                            <form action="/user/operation-evaluation" method="POST" style="display: inline;">
                                                <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                                <input type="hidden" name="rcm_id" value="{{ item.rcm_info.rcm_id }}">
                                                <input type="hidden" name="session" value="{{ item.evaluation_session }}">
                                                <button type="submit" class="btn btn-sm btn-success w-100">
                                                    <i class="fas fa-cogs"></i> 운영평가 계속
                                                </button>
                                            </form>
                                            {% else %}
                                            <a href="{{ url_for('link7.user_operation_evaluation') }}" class="btn btn-sm btn-warning w-100">
                                                <i class="fas fa-play"></i> 운영평가 시작
                                            </a>
                                            {% endif %}
                                        {% else %}
                                        <div data-bs-toggle="tooltip" data-bs-placement="top"
                                             title="설계평가를 먼저 완료해주세요">
                                            <button class="btn btn-sm btn-outline-secondary w-100" disabled style="pointer-events: none;">
                                                <i class="fas fa-lock"></i> 운영평가 (잠김)
                                            </button>
                                        </div>
                                        {% endif %}
                                    </div>
                                {% else %}
                                    <div class="text-center text-muted py-5">
                                        <i class="fas fa-inbox fa-3x mb-3"></i>
                                        <p class="mb-0">ITGC RCM이 없습니다</p>
                                    </div>
                                {% endif %}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            {% endfor %}
        {% else %}
            <!-- 빈 상태 -->
            <div class="text-center py-5">
                <div class="mb-4">
                    <i class="fas fa-tasks text-muted" style="font-size: 4rem;"></i>
                </div>
                <h4 class="text-muted mb-3">내부평가할 RCM이 없습니다</h4>
                <p class="text-muted mb-4">
                    내부평가를 진행하려면 먼저 RCM을 등록하고 접근 권한을 받아야 합니다.
                </p>
                <a href="{{ url_for('link5.user_rcm') }}" class="btn btn-primary">
                    <i class="fas fa-database me-1"></i>RCM 관리로 이동
                </a>
            </div>
        {% endif %}
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Bootstrap 툴팁 초기화
        document.addEventListener('DOMContentLoaded', function() {
            var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
            var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
                return new bootstrap.Tooltip(tooltipTriggerEl);
            });
        });
    </script>
</body>
</html>
