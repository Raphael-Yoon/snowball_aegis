<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball - 서비스 문의</title>
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <style>
        #message::placeholder {
            color: #999;
            opacity: 0.6;
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
    {% include 'navi.jsp' %}
    <div class="container py-5">
        <div class="row">
            <div class="col-md-6 d-flex align-items-center justify-content-center" style="border-right:1px solid #eee; min-height:400px;">
                <div>
                    <h2 class="mb-4 text-primary"><i class="fas fa-snowflake me-2"></i>Snowball 소개</h2>
                    <p style="font-size:1.1rem;">
                        Snowball은 내부통제 평가와 IT감사 대응을 전문적으로 하고 있습니다.<br><br>
                        <b>서비스 분야</b><br>
                        - ITGC RCM 구축<br>
                        - ITGC 설계 및 운영평가(PA)<br>
                        - ITGC 설명 및 교육<br>
                        - IT감사 대응<br>
                        - 회사 RCM에 맞춘 자동화 시스템 구축<br><br>
                        Snowball은 기업의 IT 리스크를 최소화하고, 효율적인 내부통제 환경을 구축할 수 있도록 지원합니다.
                    </p>
                </div>
            </div>
            <div class="col-md-6">
                <h2 class="mb-4 text-center"><i class="fas fa-envelope me-2"></i>서비스 문의</h2>
                {% if success is defined and success %}
                    <div class="alert alert-success text-center">문의가 성공적으로 접수되었습니다. 빠른 시일 내에 답변드리겠습니다.</div>
                {% elif success is defined and not success %}
                    <div class="alert alert-danger text-center">문의 접수에 실패했습니다.<br>{{ error }}</div>
                {% endif %}
                <form method="post" action="/link9" class="mx-auto" style="width: 80%;">
                    <input type="hidden" name="csrf_token" value="{{ csrf_token() }}"/>
                    <input type="hidden" name="form_token" value="{{ form_token }}"/>
                    <!-- Honeypot: 봇 차단용 숨김 필드 -->
                    <input type="text" name="website" class="hp-field" tabindex="-1" autocomplete="off" aria-hidden="true" value="">
                    <div class="mb-3">
                        <label for="company_name" class="form-label">회사명 *</label>
                        {% if is_logged_in %}
                        <input type="text" class="form-control" id="company_name" name="company_name" value="{{ user_info.company_name if user_info.company_name else '' }}" readonly required>
                        <small class="text-muted">로그인된 계정의 회사명이 자동으로 설정됩니다.</small>
                        {% else %}
                        <input type="text" class="form-control" id="company_name" name="company_name" placeholder="회사명을 입력하세요" required>
                        <small class="text-muted">소속 회사명을 입력해주세요.</small>
                        {% endif %}
                    </div>
                    <div class="mb-3">
                        <label for="name" class="form-label">이름</label>
                        {% if is_logged_in %}
                        <input type="text" class="form-control" id="name" name="name" value="{{ user_info.user_name }}" readonly>
                        <small class="text-muted">로그인된 계정의 사용자 이름이 자동으로 설정됩니다.</small>
                        {% else %}
                        <input type="text" class="form-control" id="name" name="name" placeholder="이름을 입력하세요 (선택사항)">
                        <small class="text-muted">문의하시는 분의 이름을 입력해주세요. (선택사항)</small>
                        {% endif %}
                    </div>
                    <div class="mb-3">
                        <label for="email" class="form-label">이메일 *</label>
                        {% if is_logged_in %}
                        <input type="email" class="form-control" id="email" name="email" value="{{ user_info.user_email }}" readonly required>
                        <small class="text-muted">로그인된 계정의 이메일 주소가 자동으로 설정됩니다.</small>
                        {% else %}
                        <input type="email" class="form-control" id="email" name="email" placeholder="이메일 주소를 입력하세요" required>
                        <small class="text-muted">답변을 받으실 이메일 주소를 입력해주세요.</small>
                        {% endif %}
                    </div>
                    <div class="mb-3">
                        <label for="message" class="form-label">문의 내용 *</label>
                        <small class="text-muted d-block mb-2">
                            💡 서비스 이용, 기술적 문제, 가입 문의 등 언제든지 편하게 문의해주세요.
                        </small>
                        <textarea class="form-control" id="message" name="message" rows="8" required placeholder="문의하실 내용을 자세히 입력해주세요.

예시) 로그인이 안 됩니다 / RCM 파일 업로드 시 오류가 발생합니다 / 평가 결과를 어떻게 해석해야 하나요? / 서비스 가입 절차를 알고 싶습니다"></textarea>
                    </div>
                    <div class="text-center">
                        <button type="submit" class="btn btn-primary btn-lg"><i class="fas fa-paper-plane me-1"></i>문의하기</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>