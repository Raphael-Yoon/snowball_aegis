<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aegis Real-time Monitoring</title>
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <!-- CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <style>
        .monitoring-card {
            border-radius: 15px;
            transition: transform 0.3s;
            border: none;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .monitoring-card:hover {
            transform: translateY(-5px);
        }
        .status-badge {
            font-size: 0.9rem;
            padding: 0.5rem 1rem;
            border-radius: 50px;
        }
        .status-pass { background-color: #d1e7dd; color: #0f5132; }
        .status-warning { background-color: #fff3cd; color: #664d03; }
        .status-fail { background-color: #f8d7da; color: #842029; }
        
        .hero-banner {
            background: linear-gradient(135deg, #0d6efd 0%, #0a58ca 100%);
            color: white;
            padding: 3rem 0;
            margin-bottom: 2rem;
            border-radius: 0 0 2rem 2rem;
        }
    </style>
</head>
<body>
    {% include 'navi.jsp' %}

    <div class="hero-banner">
        <div class="container text-center">
            <h1 class="display-4 fw-bold"><i class="fas fa-shield-halved me-3"></i>Aegis Real-time Monitoring</h1>
            <p class="lead">ITGC 상시 모니터링 및 CSR 매칭 자동 검증 시스템</p>
            
            <div class="mt-4">
                <h6 class="text-light mb-3">Monitoring In-Scope Systems</h6>
                <div class="d-flex justify-content-center gap-2">
                    {% for system in in_scope_systems %}
                    <span class="badge bg-light text-primary py-2 px-3 fs-6">
                        <i class="fas fa-server me-1"></i>{{ system }}
                    </span>
                    {% endfor %}
                </div>
            </div>

            <button class="btn btn-light btn-lg mt-4" onclick="runMonitor()">
                <i class="fas fa-play me-2"></i>모니터링 즉시 실행
            </button>
        </div>
    </div>

    <div class="container mb-5">
        <!-- Status Summary -->
        <div class="row g-4 mb-4">
            {% for cat in ['UserAccess', 'ProgramChange', 'BatchJob', 'Interface'] %}
            {% set log = latest_logs.get(cat) %}
            <div class="col-lg-3 col-md-6">
                <div class="card monitoring-card h-100">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <h5 class="card-title mb-0">
                                {% if cat == 'UserAccess' %}<i class="fas fa-users-cog text-primary"></i>
                                {% elif cat == 'ProgramChange' %}<i class="fas fa-code-branch text-success"></i>
                                {% elif cat == 'BatchJob' %}<i class="fas fa-clock text-warning"></i>
                                {% elif cat == 'Interface' %}<i class="fas fa-sync text-info"></i>
                                {% endif %}
                                {{ cat }}
                            </h5>
                            {% if log %}
                            <span class="status-badge status-{{ log.status.lower() }}">
                                {{ log.status }}
                            </span>
                            {% else %}
                            <span class="status-badge bg-secondary text-white">READY</span>
                            {% endif %}
                        </div>
                        
                        {% if log %}
                        <div class="mb-2">
                            <small class="text-muted">마지막 실행: {{ log.log_date }}</small>
                        </div>
                        <div class="d-flex justify-content-between mb-1">
                            <span>전체 건수</span>
                            <span class="fw-bold">{{ log.total_count }}</span>
                        </div>
                        <div class="d-flex justify-content-between mb-1">
                            <span>매칭 완료</span>
                            <span class="text-success">{{ log.match_count }}</span>
                        </div>
                        <div class="d-flex justify-content-between">
                            <span>미매칭 (Anomaly)</span>
                            <span class="text-danger fw-bold">{{ log.unmapped_count }}</span>
                        </div>
                        {% else %}
                        <p class="text-center py-4 text-muted">실행 이력이 없습니다.</p>
                        {% endif %}
                    </div>
                </div>
            </div>
            {% endfor %}
        </div>

        <!-- History Table -->
        <div class="card shadow-sm border-0" style="border-radius: 15px;">
            <div class="card-header bg-white py-3">
                <h5 class="mb-0"><i class="fas fa-history me-2"></i>최근 모니터링 이력</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4">No</th>
                                <th>카테고리</th>
                                <th>상태</th>
                                <th>전체/매칭/미매칭</th>
                                <th>실행 일시</th>
                                <th class="text-end pe-4">보고서</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for log in history %}
                            <tr>
                                <td class="ps-4">{{ loop.index }}</td>
                                <td>
                                    <span class="fw-bold">{{ log.category }}</span>
                                </td>
                                <td>
                                    <span class="badge status-{{ log.status.lower() }}">
                                        {{ log.status }}
                                    </span>
                                </td>
                                <td>{{ log.total_count }} / {{ log.match_count }} / <span class="{{ 'text-danger fw-bold' if log.unmapped_count > 0 else '' }}">{{ log.unmapped_count }}</span></td>
                                <td>{{ log.log_date }}</td>
                                <td class="text-end pe-4">
                                    <button class="btn btn-sm btn-outline-primary">
                                        <i class="fas fa-file-alt"></i>
                                    </button>
                                </td>
                            </tr>
                            {% else %}
                            <tr>
                                <td colspan="6" class="text-center py-5 text-muted">표시할 데이터가 없습니다.</td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Scripts -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script>
        async function runMonitor() {
            Swal.fire({
                title: '모니터링 실행 중...',
                text: '모집단 추출 및 CSR 매칭을 진행하고 있습니다.',
                allowOutsideClick: false,
                didOpen: () => {
                    Swal.showLoading();
                }
            });

            try {
                const response = await fetch('/api/aegis/run-monitor', { method: 'POST' });
                const data = await response.json();

                if (data.success) {
                    Swal.fire({
                        icon: 'success',
                        title: '모니터링 완료',
                        text: '모니터링 사이클이 성공적으로 종료되었습니다.',
                        confirmButtonText: '확인'
                    }).then(() => {
                        window.location.reload();
                    });
                } else {
                    Swal.fire('오류', data.message, 'error');
                }
            } catch (error) {
                Swal.fire('오류', '통신 중 오류가 발생했습니다.', 'error');
            }
        }
    </script>
</body>
</html>
