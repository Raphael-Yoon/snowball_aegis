<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - 내부평가 상세 - {{ rcm_info.rcm_name }}</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .detail-card {
            border: 1px solid #e9ecef;
            border-radius: 12px;
            margin-bottom: 1.5rem;
        }
        .detail-card-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1.5rem;
            border-radius: 12px 12px 0 0;
        }
        .step-status-badge {
            font-size: 0.9rem;
            padding: 0.5rem 1rem;
        }
        .progress-lg {
            height: 30px;
            font-size: 1rem;
        }
        .info-row {
            padding: 0.75rem 0;
            border-bottom: 1px solid #f0f0f0;
        }
        .info-row:last-child {
            border-bottom: none;
        }
        .info-label {
            font-weight: 600;
            color: #495057;
            min-width: 150px;
        }
        .timeline {
            position: relative;
            padding-left: 30px;
        }
        .timeline-item {
            position: relative;
            padding-bottom: 2rem;
        }
        .timeline-item:last-child {
            padding-bottom: 0;
        }
        .timeline-marker {
            position: absolute;
            left: -30px;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            border: 3px solid;
        }
        .timeline-marker.completed {
            background-color: #28a745;
            border-color: #28a745;
        }
        .timeline-marker.in-progress {
            background-color: #007bff;
            border-color: #007bff;
        }
        .timeline-marker.pending {
            background-color: #fff;
            border-color: #dee2e6;
        }
        .timeline-line {
            position: absolute;
            left: -21px;
            top: 20px;
            bottom: -10px;
            width: 2px;
            background-color: #dee2e6;
        }
        .timeline-item:last-child .timeline-line {
            display: none;
        }
    </style>
</head>
<body>
    {% include 'navi.jsp' %}

    <div class="container mt-4 mb-5">
        <!-- 헤더 -->
        <div class="row mb-4">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h2><i class="fas fa-chart-line me-2 text-primary"></i>내부평가 상세</h2>
                        <p class="text-muted mb-0">
                            <i class="fas fa-building me-1"></i>{{ rcm_info.company_name }} - {{ rcm_info.rcm_name }}
                        </p>
                    </div>
                    <div>
                        <a href="{{ url_for('link8.link8') }}" class="btn btn-outline-secondary">
                            <i class="fas fa-arrow-left me-1"></i>목록으로
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- 세션 정보 -->
        <div class="detail-card">
            <div class="detail-card-header">
                <div class="row align-items-center">
                    <div class="col-md-8">
                        <h4 class="mb-1">
                            <i class="fas fa-clipboard-list me-2"></i>{{ evaluation_session }}
                        </h4>
                        <p class="mb-0 opacity-75">평가 세션</p>
                    </div>
                    <div class="col-md-4 text-end">
                        <h3 class="mb-0">{{ progress.overall_progress }}%</h3>
                        <p class="mb-0 opacity-75">전체 진행률</p>
                    </div>
                </div>
            </div>
            <div class="card-body p-4">
                <div class="progress progress-lg mb-3">
                    <div class="progress-bar bg-success" role="progressbar"
                         style="width: {{ progress.overall_progress }}%">
                        {{ progress.overall_progress }}%
                    </div>
                </div>
            </div>
        </div>

        <!-- 평가 단계 타임라인 -->
        <div class="detail-card">
            <div class="card-header bg-light">
                <h5 class="mb-0"><i class="fas fa-tasks me-2"></i>평가 진행 단계</h5>
            </div>
            <div class="card-body p-4">
                <div class="timeline">
                    {% for step in progress.steps %}
                    <div class="timeline-item">
                        <div class="timeline-marker {{ step.status }}"></div>
                        <div class="timeline-line"></div>
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <div>
                                <h5 class="mb-1">
                                    {{ step.step }}. {{ step.name }}
                                    {% if step.status == 'completed' %}
                                    <span class="badge bg-success step-status-badge">완료</span>
                                    {% elif step.status == 'in_progress' %}
                                    <span class="badge bg-primary step-status-badge">진행중</span>
                                    {% else %}
                                    <span class="badge bg-secondary step-status-badge">대기</span>
                                    {% endif %}
                                </h5>
                                <p class="text-muted mb-2">{{ step.description }}</p>
                            </div>
                        </div>

                        {% if step.details %}
                        <div class="row">
                            <div class="col-md-6">
                                <div class="info-row d-flex">
                                    <span class="info-label">총 통제 수:</span>
                                    <span class="ms-3">
                                        {% if step.step == 1 %}
                                            {{ step.details.total_controls }}개
                                        {% else %}
                                            {{ step.details.total_controls }}개
                                        {% endif %}
                                    </span>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="info-row d-flex">
                                    <span class="info-label">완료:</span>
                                    <span class="ms-3">
                                        {% if step.step == 1 %}
                                            {{ step.details.evaluated_controls }}개
                                        {% else %}
                                            {{ step.details.completed_controls }}개
                                        {% endif %}
                                    </span>
                                </div>
                            </div>
                        </div>
                        <div class="mt-3">
                            <div class="progress" style="height: 8px;">
                                <div class="progress-bar
                                    {% if step.status == 'completed' %}bg-success
                                    {% elif step.status == 'in_progress' %}bg-primary
                                    {% else %}bg-secondary{% endif %}"
                                    role="progressbar"
                                    style="width: {{ step.details.progress }}%">
                                </div>
                            </div>
                            <small class="text-muted">진행률: {{ step.details.progress }}%</small>
                        </div>
                        {% else %}
                        <p class="text-muted fst-italic">아직 시작되지 않았습니다.</p>
                        {% endif %}

                        <!-- 액션 버튼 -->
                        <div class="mt-3">
                            {% if step.step == 1 %}
                                {% if step.status == 'completed' or step.status == 'in-progress' %}
                                <form action="/user/design-evaluation" method="POST" style="display: inline;">
                                    <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                    <input type="hidden" name="rcm_id" value="{{ rcm_info.rcm_id }}">
                                    <input type="hidden" name="session" value="{{ evaluation_session }}">
                                    <button type="submit" class="btn btn-sm
                                       {% if step.status == 'completed' %}btn-outline-success
                                       {% else %}btn-primary{% endif %}">
                                        <i class="fas fa-clipboard-check me-1"></i>
                                        {% if step.status == 'completed' %}
                                            설계평가 확인하기
                                        {% else %}
                                            설계평가 계속하기
                                        {% endif %}
                                    </button>
                                </form>
                                {% else %}
                                <div data-bs-toggle="tooltip" data-bs-placement="top"
                                     title="설계평가 화면에서 '내부평가 시작'을 먼저 진행해주세요">
                                    <button class="btn btn-sm btn-outline-secondary" disabled style="pointer-events: none;">
                                        <i class="fas fa-lock me-1"></i>설계평가 (잠김)
                                    </button>
                                </div>
                                {% endif %}
                            {% elif step.step == 2 %}
                                {% if progress.steps[0].status == 'completed' %}
                                    {% if step.status == 'completed' or step.status == 'in-progress' %}
                                    <form action="/user/operation-evaluation" method="POST" style="display: inline;">
                                        <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                                        <input type="hidden" name="rcm_id" value="{{ rcm_info.rcm_id }}">
                                        <input type="hidden" name="session" value="{{ evaluation_session }}">
                                        <button type="submit" class="btn btn-sm
                                           {% if step.status == 'completed' %}btn-outline-success
                                           {% else %}btn-success{% endif %}">
                                            <i class="fas fa-cogs me-1"></i>
                                            {% if step.status == 'completed' %}
                                                운영평가 확인하기
                                            {% else %}
                                                운영평가 계속하기
                                            {% endif %}
                                        </button>
                                    </form>
                                    {% endif %}
                                {% else %}
                                    <div data-bs-toggle="tooltip" data-bs-placement="top"
                                         title="설계평가를 먼저 완료해주세요">
                                        <button class="btn btn-sm btn-outline-secondary" disabled style="pointer-events: none;">
                                            <i class="fas fa-lock me-1"></i>운영평가 (설계평가 완료 후)
                                        </button>
                                    </div>
                                {% endif %}
                            {% endif %}
                        </div>
                    </div>
                    {% endfor %}
                </div>
            </div>
        </div>

        <!-- RCM 정보 -->
        <div class="detail-card">
            <div class="card-header bg-light">
                <h5 class="mb-0"><i class="fas fa-info-circle me-2"></i>RCM 정보</h5>
            </div>
            <div class="card-body p-4">
                <div class="row">
                    <div class="col-md-6">
                        <div class="info-row d-flex">
                            <span class="info-label">회사명:</span>
                            <span class="ms-3">{{ rcm_info.company_name }}</span>
                        </div>
                        <div class="info-row d-flex">
                            <span class="info-label">RCM 이름:</span>
                            <span class="ms-3">{{ rcm_info.rcm_name }}</span>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="info-row d-flex">
                            <span class="info-label">업로드 일자:</span>
                            <span class="ms-3">{{ rcm_info.upload_date }}</span>
                        </div>
                        {% if rcm_info.description %}
                        <div class="info-row d-flex">
                            <span class="info-label">설명:</span>
                            <span class="ms-3">{{ rcm_info.description }}</span>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>
        </div>
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
