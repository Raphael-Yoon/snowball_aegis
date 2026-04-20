<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball Aegis System</title>
    <script>
        (function() {
            var theme = localStorage.getItem('snowball-theme') || 'light';
            document.documentElement.setAttribute('data-bs-theme', theme);
        })();
    </script>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css') }}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css') }}" rel="stylesheet">
    <style>
        body { padding-top: 0 !important; }
    </style>
</head>
<body>
    <script>
        if (localStorage.getItem('snowball-theme') === 'dark') document.body.classList.add('dark-theme');
    </script>

    <!-- 히어로 섹션 -->
    <section class="hero-section">
        <div class="container">
            <div class="row align-items-center">
                <div class="col-lg-2 text-center">
                    <img src="{{ url_for('static', filename='img/logo.jpg') }}" alt="Aegis"
                         class="img-fluid logo-light" style="max-height:80px;">
                    <img src="{{ url_for('static', filename='img/logo_dark.jpg') }}" alt="Aegis"
                         class="img-fluid logo-dark" style="max-height:80px;">
                </div>
                <div class="col-lg-7 hero-content">
                    <h1 class="hero-title">Snowball Aegis System</h1>
                    <p class="hero-subtitle">ITGC 기준통제 기반 실시간 모니터링 플랫폼</p>
                </div>
                <div class="col-lg-3 text-end">
                    {% if user_name != 'Guest' %}
                    <div class="auth-info">
                        <span class="user-welcome">환영합니다, {{ user_name }}님!</span>
                        <div class="mt-2">
                            <a href="{{ url_for('aegis_monitor.dashboard') }}" class="btn btn-primary btn-sm me-1">
                                <i class="fas fa-shield-alt me-1"></i>대시보드
                            </a>
                            <a href="{{ url_for('logout') }}" class="btn btn-outline-secondary btn-sm">로그아웃</a>
                        </div>
                    </div>
                    {% else %}
                    <div class="auth-links">
                        <a href="{{ url_for('login') }}" class="login-button">
                            <i class="fas fa-sign-in-alt me-1"></i>로그인
                        </a>
                    </div>
                    {% endif %}
                    <div class="mt-2">
                        <button onclick="toggleTheme()" class="btn btn-link p-0" title="테마 전환">
                            <i id="themeIcon" class="fas fa-moon text-muted"></i>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 메인 기능 카드 -->
    <div class="container py-5">
        {% if user_name != 'Guest' %}
        <div class="row g-4 justify-content-center">

            <div class="col-md-4">
                <a href="{{ url_for('aegis_monitor.dashboard') }}" class="text-decoration-none">
                    <div class="card h-100 shadow-sm border-0 hover-card">
                        <div class="card-body text-center p-4">
                            <div class="mb-3">
                                <i class="fas fa-shield-alt fa-3x text-primary"></i>
                            </div>
                            <h5 class="card-title fw-bold">모니터링 대시보드</h5>
                            <p class="card-text text-muted small">
                                통제 × 시스템 매트릭스 기반의 실시간 현황 확인 및 배치 실행
                            </p>
                        </div>
                    </div>
                </a>
            </div>

            <div class="col-md-4">
                <a href="{{ url_for('aegis_systems.systems_list') }}" class="text-decoration-none">
                    <div class="card h-100 shadow-sm border-0 hover-card">
                        <div class="card-body text-center p-4">
                            <div class="mb-3">
                                <i class="fas fa-server fa-3x text-info"></i>
                            </div>
                            <h5 class="card-title fw-bold">시스템 관리</h5>
                            <p class="card-text text-muted small">
                                모니터링 대상 시스템 등록 및 DB 연결 관리
                            </p>
                        </div>
                    </div>
                </a>
            </div>

            <div class="col-md-4">
                <a href="{{ url_for('aegis_controls.controls_list') }}" class="text-decoration-none">
                    <div class="card h-100 shadow-sm border-0 hover-card">
                        <div class="card-body text-center p-4">
                            <div class="mb-3">
                                <i class="fas fa-tasks fa-3x text-success"></i>
                            </div>
                            <h5 class="card-title fw-bold">통제 관리</h5>
                            <p class="card-text text-muted small">
                                ITGC 기준통제(APD/PC/PD/CO) 정의 및 시스템 매핑
                            </p>
                        </div>
                    </div>
                </a>
            </div>

            <div class="col-md-4">
                <a href="{{ url_for('aegis_monitor.results_view') }}" class="text-decoration-none">
                    <div class="card h-100 shadow-sm border-0 hover-card">
                        <div class="card-body text-center p-4">
                            <div class="mb-3">
                                <i class="fas fa-chart-bar fa-3x text-warning"></i>
                            </div>
                            <h5 class="card-title fw-bold">결과 조회</h5>
                            <p class="card-text text-muted small">
                                일자별 모니터링 결과 및 예외 건수 상세 조회
                            </p>
                        </div>
                    </div>
                </a>
            </div>

            {% if user_info and user_info.get('admin_flag') == 'Y' %}
            <div class="col-md-4">
                <a href="{{ url_for('admin.admin') }}" class="text-decoration-none">
                    <div class="card h-100 shadow-sm border-0 hover-card">
                        <div class="card-body text-center p-4">
                            <div class="mb-3">
                                <i class="fas fa-user-shield fa-3x text-secondary"></i>
                            </div>
                            <h5 class="card-title fw-bold">관리자</h5>
                            <p class="card-text text-muted small">
                                사용자 및 시스템 관리
                            </p>
                        </div>
                    </div>
                </a>
            </div>
            {% endif %}

        </div>

        {% else %}
        <!-- 비로그인 안내 -->
        <div class="row justify-content-center">
            <div class="col-md-6 text-center">
                <div class="card shadow-sm border-0 p-5">
                    <i class="fas fa-lock fa-4x text-muted mb-3"></i>
                    <h5 class="fw-bold">로그인이 필요합니다</h5>
                    <p class="text-muted mb-4">Snowball Aegis는 사내 전용 시스템입니다.</p>
                    <a href="{{ url_for('login') }}" class="btn btn-primary">
                        <i class="fas fa-sign-in-alt me-1"></i>로그인
                    </a>
                </div>
            </div>
        </div>
        {% endif %}

        <!-- 시스템 소개 -->
        <div class="row mt-5 pt-4 border-top">
            <div class="col-12 text-center mb-3">
                <h6 class="text-muted fw-semibold">ITGC 4대 통제 영역</h6>
            </div>
            {% for cat, label in [('APD','Access to Programs & Data'), ('PC','Program Changes'), ('PD','Program Development'), ('CO','Computer Operations')] %}
            <div class="col-md-3 text-center mb-3">
                <span class="badge bg-primary fs-6 mb-1">{{ cat }}</span>
                <div class="small text-muted">{{ label }}</div>
            </div>
            {% endfor %}
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function toggleTheme() {
            var html = document.documentElement;
            var next = (html.getAttribute('data-bs-theme') || 'light') === 'dark' ? 'light' : 'dark';
            html.setAttribute('data-bs-theme', next);
            localStorage.setItem('snowball-theme', next);
            document.body.classList.toggle('dark-theme', next === 'dark');
            document.getElementById('themeIcon').className = next === 'dark' ? 'fas fa-sun text-muted' : 'fas fa-moon text-muted';
        }
        document.addEventListener('DOMContentLoaded', function() {
            var theme = localStorage.getItem('snowball-theme') || 'light';
            document.getElementById('themeIcon').className = theme === 'dark' ? 'fas fa-sun text-muted' : 'fas fa-moon text-muted';
        });
    </script>
</body>
</html>
