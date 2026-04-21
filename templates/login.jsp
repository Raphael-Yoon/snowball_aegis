<!DOCTYPE html>
<html>
<head>
<script>
    (function() {
        var theme = localStorage.getItem('snowball-theme') || 'light';
        document.documentElement.setAttribute('data-bs-theme', theme);
    })();
</script>
    <meta charset="UTF-8">
    <title>Snowball Aegis System - 로그인</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="{{ url_for('static', filename='css/common.css') }}">
    <link rel="stylesheet" type="text/css" href="{{ url_for('static', filename='css/style.css') }}">
    <style>
        /* 다크모드 input 스타일 */
        [data-bs-theme="dark"] input[type="email"],
        [data-bs-theme="dark"] input[type="text"],
        [data-bs-theme="dark"] input[type="password"] {
            background-color: #252930;
            border-color: #3a3f4b;
            color: #dee2e6;
        }
        [data-bs-theme="dark"] input[type="email"]:focus,
        [data-bs-theme="dark"] input[type="text"]:focus,
        [data-bs-theme="dark"] input[type="password"]:focus {
            background-color: #2e333d;
            border-color: #6ea8fe;
            color: #dee2e6;
        }
        [data-bs-theme="dark"] input::placeholder {
            color: #6c757d;
            opacity: 1;
        }
        .hp-field {
            position: absolute;
            left: -9999px;
            top: -9999px;
            width: 0;
            height: 0;
            overflow: hidden;
            opacity: 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="login-wrapper">
            <div class="login-container">
                <div class="login-header">
                    <a href="/" class="back-button">← 메인으로</a>
                    <h2>로그인</h2>
                </div>
            {% with messages = get_flashed_messages(with_categories=true) %}
            {% for category, msg in messages %}
                <div class="{{ 'error-message' if category == 'error' else 'success-message' }}">{{ msg }}</div>
            {% endfor %}
            {% endwith %}
            {% if error %}
                <div class="error-message">{{ error }}</div>
            {% endif %}
            {% if message %}
                <div class="success-message">{{ message }}</div>
            {% endif %}
            
            {% if not step or step != 'verify' %}
            <!-- 1단계: 이메일 입력 및 OTP 요청 -->
            <form method="POST" action="{{ url_for('login') }}">
                <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                <input type="hidden" name="action" value="send_otp">
                <input type="hidden" name="method" value="email">
                <div class="form-group">
                    <label for="email">이메일:</label>
                    <input type="email" id="email" name="email" required
                           placeholder="등록된 이메일 주소를 입력하세요">
                </div>
                <button type="submit" class="btn-primary">인증 코드 발송</button>
            </form>
            
            <!-- 관리자 로그인 버튼 (로컬호스트 및 pythonanywhere) -->
            {% if remote_addr == '127.0.0.1' or request.host.startswith('127.0.0.1') or request.host.startswith('localhost') or request.host.startswith('192.168.') or request.host.startswith('snowball.pythonanywhere.com') %}
            <div class="admin-login-section" style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd;">
                <form method="POST" action="{{ url_for('login') }}">
                    <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                    <input type="hidden" name="action" value="admin_login">
                    <button type="submit" class="btn-outline" style="background-color: #28a745; color: white; border-color: #28a745;">
                        <i class="fas fa-shield-alt"></i> 관리자 로그인
                    </button>
                </form>
            </div>
            {% endif %}
            {% else %}
            <!-- 2단계: OTP 코드 입력 -->
            <div class="otp-info">
                {% if show_direct_login %}
                <p><strong>{{ email }}</strong> 사용자의 인증 코드를 입력해주세요.</p>
                <p>6자리 인증 코드를 입력하세요.</p>
                {% else %}
                <p><strong>{{ email }}</strong>로 인증 코드를 발송했습니다.</p>
                <p>이메일을 확인하고 6자리 인증 코드를 입력해주세요.</p>
                {% endif %}
            </div>
            <form method="POST" action="{{ url_for('login') }}">
                <input type="hidden" name="csrf_token" value="{{ csrf_token() }}">
                <input type="hidden" name="action" value="verify_otp">
                <div class="form-group">
                    <label for="otp_code">인증 코드:</label>
                    <input type="text" id="otp_code" name="otp_code" required 
                           placeholder="000000" maxlength="6" pattern="[0-9]{6}"
                           style="font-size: 20px; text-align: center; letter-spacing: 5px;">
                </div>
                <div class="button-group">
                    <button type="submit" class="btn-primary">로그인</button>
                    <a href="{{ url_for('login') }}" class="btn-outline">
                        <i class="fas fa-undo me-1"></i>다시 시작
                    </a>
                </div>
            </form>
            {% endif %}
            </div>
            
            <div class="info-container">
                <div class="info-header">
                    <h3><i class="fas fa-shield-alt"></i> Snowball Aegis System</h3>
                    <p class="info-subtitle">전문적인 내부통제 평가 솔루션</p>
                </div>
                
                <div class="feature-list">
                    <div class="feature-item">
                        <div class="feature-icon">
                            <i class="fas fa-robot"></i>
                        </div>
                        <div class="feature-content">
                            <h4>AI 검토 기능</h4>
                            <p>인터뷰 결과를 AI가 분석하여 더욱 정확하고 상세한 평가 보고서를 제공합니다.</p>
                        </div>
                    </div>
                    
                    <div class="feature-item">
                        <div class="feature-icon">
                            <i class="fas fa-cogs"></i>
                        </div>
                        <div class="feature-content">
                            <h4>맞춤 RCM 기능</h4>
                            <p>각 회사의 특성에 맞는 신뢰성 중심 유지보수 시스템을 제공합니다.</p>
                        </div>
                    </div>
                    
                    <div class="feature-item">
                        <div class="feature-icon">
                            <i class="fas fa-chart-line"></i>
                        </div>
                        <div class="feature-content">
                            <h4>고급 분석 도구</h4>
                            <p>상세한 분석 리포트와 개선 방안을 통해 내부통제 수준을 향상시킵니다.</p>
                        </div>
                    </div>
                    
                    <div class="feature-item">
                        <div class="feature-icon">
                            <i class="fas fa-headset"></i>
                        </div>
                        <div class="feature-content">
                            <h4>전문가 지원</h4>
                            <p>숙련된 전문가들이 직접 지원하여 최고 품질의 서비스를 보장합니다.</p>
                        </div>
                    </div>
                </div>
                
                <div class="pricing-info">

        </div>
    </div>
    
    
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const showInquiryBtn = document.getElementById('showInquiryBtn');
            const inquiryContainer = document.getElementById('inquiryContainer');
            
            // 서비스 문의 성공/실패 메시지가 있으면 자동으로 폼 열기
            {% if service_inquiry_success or service_inquiry_error %}
            inquiryContainer.style.display = 'block';
            inquiryContainer.scrollIntoView({ 
                behavior: 'smooth', 
                block: 'nearest' 
            });
            {% endif %}
            
            if (showInquiryBtn) {
                showInquiryBtn.addEventListener('click', function() {
                    if (inquiryContainer.style.display === 'none') {
                        inquiryContainer.style.display = 'block';
                        // 스크롤 효과로 폼으로 이동
                        inquiryContainer.scrollIntoView({ 
                            behavior: 'smooth', 
                            block: 'nearest' 
                        });
                    } else {
                        inquiryContainer.style.display = 'none';
                    }
                });
            }
        });
    </script>
</body>
</html>