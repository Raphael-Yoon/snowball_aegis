<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball Aegis System</title>
    <!-- 다크모드 FOUC 방지 -->
    <script>
        (function() {
            var theme = localStorage.getItem('snowball-theme') || 'light';
            document.documentElement.setAttribute('data-bs-theme', theme);
        })();
    </script>
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <!-- CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <style>
        /* index 페이지에는 navbar가 없으므로 padding-top 제거 */
        body {
            padding-top: 0 !important;
        }
        [data-bs-theme="dark"] .alert-info {
            color: #000 !important;
        }
    </style>
</head>

<body>
    <!-- 히어로 섹션 -->
    <section class="hero-section">
        <div class="container">
            <div class="row align-items-center">
                <div class="col-lg-2">
                    <img src="{{ url_for('static', filename='img/snowball.png')}}" alt="Snowball"
                        class="img-fluid" style="max-height: 80px; width: auto;">
                </div>
                <div class="col-lg-8 hero-content">
                    <h1 class="hero-title">Snowball Aegis System</h1>
                    <p class="hero-subtitle">내부회계관리제도(ICFR) 평가 및 IT감사 대응 종합 솔루션</p>
                </div>
                <div class="col-lg-2 text-end">
                    {% if user_name != 'Guest' %}
                    <div class="auth-info">
                        <span class="user-welcome">환영합니다, {{ user_name }}님!</span>
                        {% if session.get('original_admin_id') %}
                        <div class="mt-1">
                            <small class="text-warning">
                                <i class="fas fa-user-secret me-1"></i>관리자가 {{ user_name }} 사용자로 스위치 중
                            </small>
                        </div>
                        <a href="/admin/switch_back" class="btn btn-sm btn-danger ms-2" title="관리자로 돌아가기">
                            <i class="fas fa-undo me-1"></i>관리자로 돌아가기
                        </a>
                        {% elif user_info and user_info.get('admin_flag') == 'Y' %}
                        <a href="/admin" class="btn btn-sm btn-warning ms-2" title="관리자 메뉴">
                            <i class="fas fa-user-shield me-1"></i>관리자
                        </a>
                        {% endif %}
                        <a href="{{ url_for('logout') }}" class="btn btn-sm btn-outline-secondary ms-2">로그아웃</a>
                    </div>
                    {% else %}
                    <div class="auth-links">
                        <a href="{{ url_for('login') }}" class="login-button">
                            <i class="fas fa-sign-in-alt"></i>
                            로그인
                        </a>
                    </div>
                    {% endif %}
                </div>
            </div>
        </div>
    </section>


    <!-- 기능 섹션 -->
    <section id="features" class="py-4">
        <div class="container">
            {% if is_logged_in %}
            <!-- 로그인 상태: Private 섹션 먼저 표시 -->
            <div class="row g-4 justify-content-center" id="private-services">
                <div class="col-12">
                    <h2 class="section-title"><i class="fas fa-lock me-2"></i>Private</h2>
                </div>

                <!-- 위 3개: Dashboard, RCM, 정보보호공시 -->
                <div class="col-lg-3 col-md-6">
                    <div class="feature-card border-info h-100">
                        <img src="{{ url_for('static', filename='img/dashboard.jpg')}}" class="feature-img"
                            alt="Dashboard" onerror="this.src='{{ url_for('static', filename='img/testing.jpg')}}';">
                        <div class="card-body p-4 d-flex flex-column">
                            <h5 class="feature-title text-center"><i class="fas fa-chart-pie me-2"></i>Dashboard</h5>
                            <p class="feature-description">ELC, TLC, ITGC 평가 결과를 통합 조회하고 종합 리포트를 생성합니다.</p>
                            <div class="text-center mt-auto">
                                <a href="{{ url_for('link8.link8') }}" class="feature-link" data-bs-toggle="tooltip"
                                    data-bs-placement="top" data-bs-html="true"
                                    title="<div>• ELC, TLC, ITGC 통합 결과 조회<br>• 통제 현황 종합 분석<br>• 자동 리포트 생성<br>• 트렌드 분석 및 인사이트</div>">자세히
                                    보기</a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-lg-3 col-md-6">
                    <div class="feature-card border-primary h-100">
                        <img src="{{ url_for('static', filename='img/rcm_inquiry.jpg')}}" class="feature-img" alt="RCM"
                            onerror="this.src='{{ url_for('static', filename='img/testing.jpg')}}';">
                        <div class="card-body p-4 d-flex flex-column">
                            <h5 class="feature-title text-center"><i class="fas fa-database me-2"></i>RCM</h5>
                            <p class="feature-description">위험통제매트릭스(RCM) 데이터를 조회하고 관리할 수 있습니다.</p>
                            <div class="text-center mt-auto">
                                <a href="/rcm" class="feature-link" data-bs-toggle="tooltip"
                                    data-bs-placement="top" data-bs-html="true"
                                    title="<div>• 위험통제매트릭스(RCM) 데이터 조회<br>• 통제항목별 상세 정보 확인<br>• 카테고리별 RCM 관리 (ELC/TLC/ITGC)<br>• 엑셀 업로드 및 다운로드 지원</div>">자세히
                                    보기</a>
                            </div>
                        </div>
                    </div>
                </div>


            </div>

            <!-- 아래 3개: ELC, TLC, ITGC -->
            <div class="row g-4 mt-3 justify-content-center">
                <div class="col-lg-3 col-md-6">
                    <div class="feature-card border-success h-100">
                        <img src="{{ url_for('static', filename='img/elc.jpg')}}" class="feature-img" alt="ELC"
                            onerror="this.src='{{ url_for('static', filename='img/elc.png')}}';">
                        <div class="card-body p-4 d-flex flex-column">
                            <h5 class="feature-title text-center"><i class="fas fa-building me-2"></i>ELC</h5>
                            <p class="feature-description">전사수준통제 설계평가 및 운영평가를 수행합니다.</p>
                            <div class="text-center mt-auto">
                                <a href="{{ url_for('link6.elc_design_evaluation') }}" class="feature-link"
                                    data-bs-toggle="tooltip" data-bs-placement="top" data-bs-html="true"
                                    title="<div>• Entity Level Controls 평가<br>• 설계평가 및 운영평가 통합<br>• 수동통제 중심 평가<br>• 평가 결과 리포트 생성</div>">자세히
                                    보기</a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-lg-3 col-md-6">
                    <div class="feature-card border-warning h-100">
                        <img src="{{ url_for('static', filename='img/tlc.jpg')}}" class="feature-img" alt="TLC"
                            onerror="this.src='{{ url_for('static', filename='img/tlc.png')}}';">
                        <div class="card-body p-4 d-flex flex-column">
                            <h5 class="feature-title text-center"><i class="fas fa-exchange-alt me-2"></i>TLC</h5>
                            <p class="feature-description">거래수준통제 설계평가 및 운영평가를 수행합니다.</p>
                            <div class="text-center mt-auto">
                                <a href="{{ url_for('link6.tlc_evaluation') }}" class="feature-link"
                                    data-bs-toggle="tooltip" data-bs-placement="top" data-bs-html="true"
                                    title="<div>• Transaction Level Controls 평가<br>• 설계평가 및 운영평가 통합<br>• 자동통제 포함 평가<br>• 평가 결과 리포트 생성</div>">자세히
                                    보기</a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-lg-3 col-md-6">
                    <div class="feature-card border-danger h-100">
                        <img src="{{ url_for('static', filename='img/itgc.jpg')}}" class="feature-img" alt="ITGC"
                            onerror="this.src='{{ url_for('static', filename='img/itgc.png')}}';">
                        <div class="card-body p-4 d-flex flex-column">
                            <h5 class="feature-title text-center"><i class="fas fa-server me-2"></i>ITGC</h5>
                            <p class="feature-description">IT일반통제 설계평가 및 운영평가를 수행합니다.</p>
                            <div class="text-center mt-auto">
                                <a href="{{ url_for('link6.itgc_evaluation') }}" class="feature-link"
                                    data-bs-toggle="tooltip" data-bs-placement="top" data-bs-html="true"
                                    title="<div>• IT General Controls 평가<br>• 설계평가 및 운영평가 통합<br>• 자동통제 및 수동통제 평가<br>• 기준통제 매핑 및 리포트 생성</div>">자세히
                                    보기</a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            {% else %}
                <!-- 비로그인 상태: Private 섹션 미리보기 (흐리게) -->
                <div class="row g-4 mt-3 justify-content-center" id="private-services" style="opacity: 0.4;">
                    <div class="col-12">
                        <h2 class="section-title"><i class="fas fa-lock me-2"></i>Private</h2>
                        <div class="alert alert-info text-center"
                            style="opacity: 1; pointer-events: auto; position: relative; z-index: 10; color: #000 !important; font-weight: bold;">
                            <i class="fas fa-lock me-2"></i>
                            Private 서비스를 이용하시려면 <a href="/login" class="alert-link" style="color: #000 !important; font-weight: bold;">로그인</a>이 필요합니다.
                        </div>
                    </div>

                    <!-- 위 3개: Dashboard, RCM, 정보보호공시 -->
                    <div class="col-lg-3 col-md-6">
                        <div class="feature-card border-info h-100">
                            <img src="{{ url_for('static', filename='img/dashboard.jpg')}}" class="feature-img" alt="Dashboard" onerror="this.src='{{ url_for('static', filename='img/itgc.jpg')}}';">
                            <div class="card-body p-4 d-flex flex-column">
                                <h5 class="feature-title text-center"><i class="fas fa-chart-pie me-2"></i>Dashboard</h5>
                                <p class="feature-description">ELC, TLC, ITGC 평가 결과를 통합 조회하고 종합 리포트를 생성합니다.</p>
                                <div class="text-center mt-auto">
                                    <a href="/link8" class="feature-link" data-bs-toggle="tooltip" data-bs-placement="top" data-bs-html="true" title="<div>• ELC, TLC, ITGC 통합 결과 조회<br>• 통제 현황 종합 분석<br>• 자동 리포트 생성<br>• 트렌드 분석 및 인사이트</div>">자세히 보기</a>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-lg-3 col-md-6">
                        <div class="feature-card border-primary h-100">
                            <img src="{{ url_for('static', filename='img/analysis_results.png')}}" class="feature-img" alt="Monitoring" onerror="this.src='{{ url_for('static', filename='img/itgc.jpg')}}';">
                            <div class="card-body p-4 d-flex flex-column">
                                <h5 class="feature-title text-center"><i class="fas fa-shield-halved me-2"></i>Monitoring</h5>
                                <p class="feature-description">모집단 추출 및 CSR 승인 자동 매칭을 통한 실시간 ITGC 모니터링을 수행합니다.</p>
                                <div class="text-center mt-auto">
                                    <a href="/aegis/monitor" class="feature-link" data-bs-toggle="tooltip" data-bs-placement="top" data-bs-html="true" title="<div>• 실시간 모집단 자동 추출<br>• CSR 승인 데이터 매칭 검증<br>• 이상 징후 조기 식별<br>• 모니터링 이력 관리</div>">자세히 보기</a>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-lg-3 col-md-6">
                        <div class="feature-card border-primary h-100">
                            <img src="{{ url_for('static', filename='img/rcm_inquiry.jpg')}}" class="feature-img"
                                alt="RCM" onerror="this.src='{{ url_for('static', filename='img/testing.jpg')}}';">
                            <div class="card-body p-4 d-flex flex-column">
                                <h5 class="feature-title text-center"><i class="fas fa-database me-2"></i>RCM</h5>
                                <p class="feature-description">위험통제매트릭스(RCM) 데이터를 조회하고 관리할 수 있습니다.</p>
                                <div class="text-center mt-auto">
                                    <a href="/rcm" class="feature-link" data-bs-toggle="tooltip"
                                        data-bs-placement="top" data-bs-html="true"
                                        title="<div>• 위험통제매트릭스(RCM) 데이터 조회<br>• 통제항목별 상세 정보 확인<br>• 카테고리별 RCM 관리 (ELC/TLC/ITGC)<br>• 엑셀 업로드 및 다운로드 지원</div>">자세히
                                        보기</a>
                                </div>
                            </div>
                        </div>
                    </div>


                </div>

                <!-- 아래 3개: ELC, TLC, ITGC -->
                <div class="row g-4 mt-3 justify-content-center" style="opacity: 0.4;">
                    <div class="col-lg-3 col-md-6">
                        <div class="feature-card border-success h-100">
                            <img src="{{ url_for('static', filename='img/elc.jpg')}}" class="feature-img" alt="ELC"
                                onerror="this.src='{{ url_for('static', filename='img/elc.png')}}'">
                            <div class="card-body p-4 d-flex flex-column">
                                <h5 class="feature-title text-center"><i class="fas fa-building me-2"></i>ELC</h5>
                                <p class="feature-description">전사수준통제 설계평가 및 운영평가를 수행합니다.</p>
                                <div class="text-center mt-auto">
                                    <a href="/elc/design-evaluation" class="feature-link" data-bs-toggle="tooltip"
                                        data-bs-placement="top" data-bs-html="true"
                                        title="<div>• Entity Level Controls 평가<br>• 설계평가 및 운영평가<br>• 수동통제 중심 평가<br>• 평가 결과 리포트 생성</div>">자세히
                                        보기</a>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-lg-3 col-md-6">
                        <div class="feature-card border-warning h-100">
                            <img src="{{ url_for('static', filename='img/tlc.jpg')}}" class="feature-img" alt="TLC"
                                onerror="this.src='{{ url_for('static', filename='img/tlc.png')}}'">
                            <div class="card-body p-4 d-flex flex-column">
                                <h5 class="feature-title text-center"><i class="fas fa-exchange-alt me-2"></i>TLC</h5>
                                <p class="feature-description">거래수준통제 설계평가 및 운영평가를 수행합니다.</p>
                                <div class="text-center mt-auto">
                                    <a href="/tlc/design-evaluation" class="feature-link" data-bs-toggle="tooltip"
                                        data-bs-placement="top" data-bs-html="true"
                                        title="<div>• Transaction Level Controls 평가<br>• 설계평가 및 운영평가<br>• 자동통제 포함 평가<br>• 평가 결과 리포트 생성</div>">자세히
                                        보기</a>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-lg-3 col-md-6">
                        <div class="feature-card border-danger h-100">
                            <img src="{{ url_for('static', filename='img/itgc.jpg')}}" class="feature-img" alt="ITGC"
                                onerror="this.src='{{ url_for('static', filename='img/itgc.png')}}'">
                            <div class="card-body p-4 d-flex flex-column">
                                <h5 class="feature-title text-center"><i class="fas fa-server me-2"></i>ITGC</h5>
                                <p class="feature-description">IT일반통제 설계평가 및 운영평가를 수행합니다.</p>
                                <div class="text-center mt-auto">
                                    <a href="/user/design-evaluation" class="feature-link" data-bs-toggle="tooltip"
                                        data-bs-placement="top" data-bs-html="true"
                                        title="<div>• IT General Controls 평가<br>• 설계평가 및 운영평가 통합<br>• 자동통제 및 수동통제 평가<br>• 기준통제 매핑 및 리포트 생성</div>">자세히
                                        보기</a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 툴팁 안내 메시지 (비로그인 상태에서만 표시) -->
                <div class="row mt-4">
                    <div class="col-12">
                        <div class="text-center">
                            <small class="text-muted">
                                <i class="fas fa-info-circle me-1"></i>
                                각 서비스의 <strong>"자세히 보기"</strong> 버튼에 마우스를 올리시면 상세 설명을 확인하실 수 있습니다.
                            </small>
                        </div>
                    </div>
                </div>
                {% endif %}

            </div>
    </section>

    <!-- Contact Us 바로가기 -->
    <section class="py-2" style="display: none;">
        <div class="container text-center">
            <a href="/link9" class="btn btn-outline-primary btn-lg">
                <i class="fas fa-envelope me-1"></i>Contact Us
            </a>
        </div>
    </section>

    <!-- 다크모드 플로팅 버튼 -->
    <button id="themeToggle" onclick="toggleTheme()" title="다크/라이트 모드 전환"
            style="position:fixed; bottom:1.5rem; right:1.5rem; z-index:9999;">
        <i id="themeIcon" class="fas fa-moon"></i>
    </button>

    <!-- JavaScript -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

    <!-- 세션 관리 및 RCM 기능 -->
    <script>
        // 다크모드 토글
        function toggleTheme() {
            var html = document.documentElement;
            var current = html.getAttribute('data-bs-theme') || 'light';
            var next = current === 'dark' ? 'light' : 'dark';
            html.setAttribute('data-bs-theme', next);
            localStorage.setItem('snowball-theme', next);
            updateThemeIcon(next);
        }
        function updateThemeIcon(theme) {
            var icon = document.getElementById('themeIcon');
            if (!icon) return;
            icon.className = theme === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
        }
        document.addEventListener('DOMContentLoaded', function() {
            updateThemeIcon(localStorage.getItem('snowball-theme') || 'light');
        });

        window.isLoggedIn = {{ 'true' if is_logged_in else 'false' }};

        // 툴팁 초기화
        document.addEventListener('DOMContentLoaded', function () {
            var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
            var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
                return new bootstrap.Tooltip(tooltipTriggerEl, {
                    delay: { show: 500, hide: 100 },
                    container: 'body'
                });
            });
        });


        // 빠른 접근 모달 표시
        function showQuickAccess() {
            if (window.isLoggedIn) {
                fetch('/api/rcm-list')
                    .then(response => response.json())
                    .then(data => {
                        if (data.success && data.rcms.length > 0) {
                            showQuickAccessModal(data.rcms);
                        } else {
                            alert('접근 가능한 RCM이 없습니다.');
                        }
                    })
                    .catch(error => {
                        console.error('RCM 목록 로드 오류:', error);
                        alert('RCM 목록을 불러오는 중 오류가 발생했습니다.');
                    });
            } else {
                alert('로그인이 필요합니다.');
            }
        }

        // 빠른 접근 모달 생성 및 표시
        function showQuickAccessModal(rcms) {
            // 기존 모달이 있다면 제거
            const existingModal = document.getElementById('quickAccessModal');
            if (existingModal) {
                existingModal.remove();
            }

            // 모달 HTML 생성
            const modalHtml = `
                <div class="modal fade" id="quickAccessModal" tabindex="-1">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title">
                                    <i class="fas fa-bolt me-2"></i>RCM 빠른 접근
                                </h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                <div class="row g-3">
                                    ${rcms.map(rcm => `
                                        <div class="col-md-6">
                                            <div class="card border-primary">
                                                <div class="card-body">
                                                    <h6 class="card-title">${rcm.rcm_name}</h6>
                                                    <p class="card-text small">${rcm.company_name}</p>
                                                    <div class="d-flex justify-content-between align-items-center">
                                                        <span class="badge bg-${rcm.permission_type === 'admin' ? 'danger' : 'success'}">
                                                            ${rcm.permission_type === 'admin' ? '관리자' : '읽기'}
                                                        </span>
                                                        <a href="/rcm/${rcm.rcm_id}/select" class="btn btn-sm btn-primary">
                                                            <i class="fas fa-eye me-1"></i>보기
                                                        </a>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    `).join('')}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;

            // 모달을 body에 추가
            document.body.insertAdjacentHTML('beforeend', modalHtml);

            // 모달 표시
            const modal = new bootstrap.Modal(document.getElementById('quickAccessModal'));
            modal.show();
        }

        // 평가 유형 선택 함수
        async function checkEvaluationType(controlType, designUrl, operationUrl) {
            try {
                // API 호출하여 운영평가 존재 여부 확인
                const response = await fetch(`/api/check-operation-evaluation/${controlType}`);
                const data = await response.json();

                if (data.has_operation_evaluation) {
                    // 운영평가가 있으면 모달 표시
                    showEvaluationTypeModal(controlType, designUrl, operationUrl, data.evaluation_sessions);
                } else {
                    // 운영평가가 없으면 바로 설계평가로 이동
                    window.location.href = designUrl;
                }
            } catch (error) {
                console.error('Error checking operation evaluation:', error);
                // 에러 발생 시 기본 동작 (설계평가로 이동)
                window.location.href = designUrl;
            }
        }

        // 평가 유형 선택 모달 표시
        function showEvaluationTypeModal(controlType, designUrl, operationUrl, evaluationSessions) {
            const modalId = 'evaluationTypeModal';

            // 기존 모달 제거
            const existingModal = document.getElementById(modalId);
            if (existingModal) {
                existingModal.remove();
            }

            const modalHtml = `
                <div class="modal fade" id="${modalId}" tabindex="-1" aria-labelledby="${modalId}Label" aria-hidden="true">
                    <div class="modal-dialog modal-dialog-centered">
                        <div class="modal-content">
                            <div class="modal-header bg-primary text-white">
                                <h5 class="modal-title" id="${modalId}Label">
                                    <i class="fas fa-clipboard-check me-2"></i>${controlType} 평가 유형 선택
                                </h5>
                                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                            </div>
                            <div class="modal-body">
                                <p class="mb-4">진행하실 평가 유형을 선택해주세요:</p>
                                <div class="d-grid gap-3">
                                    <a href="${designUrl}" class="btn btn-outline-primary btn-lg">
                                        <i class="fas fa-pencil-ruler me-2"></i>설계평가
                                        <small class="d-block mt-1 text-muted">통제 설계의 적정성을 평가합니다</small>
                                    </a>
                                    <a href="${operationUrl}" class="btn btn-outline-success btn-lg">
                                        <i class="fas fa-tasks me-2"></i>운영평가
                                        <small class="d-block mt-1 text-muted">통제 운영의 효과성을 평가합니다</small>
                                        ${evaluationSessions.length > 0 ? `<small class="d-block mt-1 text-success"><i class="fas fa-check-circle me-1"></i>진행 중인 세션 ${evaluationSessions.length}개</small>` : ''}
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;

            document.body.insertAdjacentHTML('beforeend', modalHtml);
            const modal = new bootstrap.Modal(document.getElementById(modalId));
            modal.show();

            // 모달 닫힐 때 제거
            document.getElementById(modalId).addEventListener('hidden.bs.modal', function () {
                this.remove();
            });
        }

    </script>
    <!-- <script src="{{ url_for('static', filename='js/session-manager.js') }}"></script> -->

</body>

</html>