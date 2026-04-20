<!DOCTYPE html>
<html lang="ko">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball Aegis</title>
    <script>
        (function() {
            var theme = localStorage.getItem('snowball-theme') || 'light';
            document.documentElement.setAttribute('data-bs-theme', theme);
        })();
    </script>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="{{ url_for('static', filename='css/common.css') }}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css') }}" rel="stylesheet">
</head>

<body>
    <script>
        if (localStorage.getItem('snowball-theme') === 'dark') {
            document.body.classList.add('dark-theme');
        }
    </script>

    <nav class="navbar navbar-expand-lg fixed-top">
        <div class="container-fluid px-4">
            <a class="navbar-brand" href="{{ url_for('index') }}">
                <img src="{{ url_for('static', filename='img/logo.jpg') }}" class="logo logo-light" alt="Aegis">
                <img src="{{ url_for('static', filename='img/logo_dark.jpg') }}" class="logo logo-dark" alt="Aegis">
                <span class="ms-2 fw-bold text-primary d-none d-sm-inline">Aegis</span>
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    {% if is_logged_in %}
                    <li class="nav-item">
                        <a href="{{ url_for('index') }}" class="nav-link">
                            <i class="fas fa-home me-1"></i>홈
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ url_for('aegis_monitor.dashboard') }}" class="nav-link">
                            <i class="fas fa-shield-alt me-1"></i>모니터링
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ url_for('aegis_systems.systems_list') }}" class="nav-link">
                            <i class="fas fa-server me-1"></i>시스템 관리
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ url_for('aegis_controls.controls_list') }}" class="nav-link">
                            <i class="fas fa-tasks me-1"></i>통제 관리
                        </a>
                    </li>
                    {% if user_info and user_info.get('admin_flag') == 'Y' %}
                    <li class="nav-item">
                        <a href="{{ url_for('admin.admin') }}" class="nav-link">
                            <i class="fas fa-user-shield me-1"></i>Admin
                        </a>
                    </li>
                    {% endif %}
                    {% endif %}
                </ul>

                <ul class="navbar-nav align-items-center">
                    <li class="nav-item">
                        <button id="themeToggle" onclick="toggleTheme()" class="btn btn-link nav-link" title="다크/라이트 모드 전환">
                            <i id="themeIcon" class="fas fa-moon"></i>
                        </button>
                    </li>
                    {% if is_logged_in %}
                    <li class="nav-item">
                        <span class="navbar-text me-2 company-info">
                            <i class="fas fa-building me-1"></i>
                            {{ user_info.company_name if user_info and user_info.company_name else '회사명 미등록' }}
                        </span>
                    </li>
                    <li class="nav-item">
                        <a href="{{ url_for('logout') }}" class="nav-link logout-link">
                            <i class="fas fa-sign-out-alt me-1"></i>로그아웃
                        </a>
                    </li>
                    {% else %}
                    <li class="nav-item">
                        <a href="{{ url_for('login') }}" class="nav-link login-nav-button">
                            <i class="fas fa-sign-in-alt me-1"></i>로그인
                        </a>
                    </li>
                    {% endif %}
                </ul>
            </div>
        </div>
    </nav>

    <script>
        function toggleTheme() {
            var html = document.documentElement;
            var current = html.getAttribute('data-bs-theme') || 'light';
            var next = current === 'dark' ? 'light' : 'dark';
            html.setAttribute('data-bs-theme', next);
            localStorage.setItem('snowball-theme', next);
            document.body.classList.toggle('dark-theme', next === 'dark');
            document.getElementById('themeIcon').className = next === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
        }

        document.addEventListener('DOMContentLoaded', function () {
            var theme = localStorage.getItem('snowball-theme') || 'light';
            document.getElementById('themeIcon').className = theme === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
        });
    </script>
</body>
</html>
