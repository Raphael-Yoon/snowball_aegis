<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - 활동 로그</title>
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

    <div class="container mt-4">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h1><i class="fas fa-list me-2"></i>사용자 활동 로그</h1>
            <a href="/admin" class="btn btn-outline-secondary">
                <i class="fas fa-arrow-left me-1"></i>관리자 대시보드
            </a>
        </div>

        <!-- 필터 -->
        <div class="card mb-4">
            <div class="card-body">
                <form method="GET" action="/admin/logs">
                    <div class="row">
                        <div class="col-md-4">
                            <label class="form-label">사용자 필터</label>
                            <select class="form-select" name="user_id">
                                <option value="">전체 사용자</option>
                                {% for user in users %}
                                <option value="{{ user.user_id }}" {% if user_filter and user_filter|int == user.user_id %}selected{% endif %}>
                                    {{ user.user_name }} ({{ user.user_email }})
                                </option>
                                {% endfor %}
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">작업 유형 필터</label>
                            <select class="form-select" name="action_type">
                                <option value="">전체 작업</option>
                                <option value="PAGE_ACCESS" {% if action_filter == 'PAGE_ACCESS' %}selected{% endif %}>페이지 접근</option>
                                <option value="FORM_SUBMIT" {% if action_filter == 'FORM_SUBMIT' %}selected{% endif %}>폼 제출</option>
                                <option value="LOGIN" {% if action_filter == 'LOGIN' %}selected{% endif %}>로그인</option>
                                <option value="LOGOUT" {% if action_filter == 'LOGOUT' %}selected{% endif %}>로그아웃</option>
                            </select>
                        </div>
                        <div class="col-md-4 d-flex align-items-end">
                            <button type="submit" class="btn btn-primary me-2">
                                <i class="fas fa-search me-1"></i>필터 적용
                            </button>
                            <a href="/admin/logs" class="btn btn-outline-secondary">
                                <i class="fas fa-undo me-1"></i>초기화
                            </a>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <!-- 통계 정보 -->
        <div class="row mb-4">
            <div class="col-md-12">
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    총 <strong>{{ total_count }}</strong>개의 활동 로그가 있습니다.
                </div>
            </div>
        </div>

        <!-- 로그 테이블 -->
        <div class="card">
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead class="table-dark">
                            <tr>
                                <th>시간</th>
                                <th>사용자</th>
                                <th>작업</th>
                                <th>페이지</th>
                                <th>IP 주소</th>
                                <th>추가 정보</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for log in logs %}
                            <tr>
                                <td>
                                    <small>{{ log.access_time[:19] if log.access_time else '-' }}</small>
                                </td>
                                <td>
                                    <strong>{{ log.user_name or '-' }}</strong><br>
                                    <small class="text-muted">{{ log.user_email or '-' }}</small>
                                </td>
                                <td>
                                    {% if log.action_type == 'PAGE_ACCESS' %}
                                        <span class="badge bg-primary">페이지 접근</span>
                                    {% elif log.action_type == 'FORM_SUBMIT' %}
                                        <span class="badge bg-success">폼 제출</span>
                                    {% elif log.action_type == 'LOGIN' %}
                                        <span class="badge bg-info">로그인</span>
                                    {% elif log.action_type == 'LOGOUT' %}
                                        <span class="badge bg-warning">로그아웃</span>
                                    {% else %}
                                        <span class="badge bg-secondary">{{ log.action_type }}</span>
                                    {% endif %}
                                </td>
                                <td>
                                    <strong>{{ log.page_name or '-' }}</strong><br>
                                    <small class="text-muted">{{ log.url_path or '-' }}</small>
                                </td>
                                <td>
                                    <code>{{ log.ip_address or '-' }}</code>
                                </td>
                                <td>
                                    <small>{{ log.additional_info or '-' }}</small>
                                </td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>

                {% if not logs %}
                <div class="text-center py-4">
                    <i class="fas fa-list fa-3x text-muted mb-3"></i>
                    <p class="text-muted">조건에 맞는 로그가 없습니다.</p>
                </div>
                {% endif %}
            </div>
        </div>

        <!-- 페이지네이션 -->
        {% if total_pages > 1 %}
        <nav aria-label="로그 페이지네이션" class="mt-4">
            <ul class="pagination justify-content-center">
                <!-- 이전 페이지 -->
                {% if current_page > 1 %}
                <li class="page-item">
                    <a class="page-link" href="?page={{ current_page - 1 }}{% if user_filter %}&user_id={{ user_filter }}{% endif %}{% if action_filter %}&action_type={{ action_filter }}{% endif %}">
                        <i class="fas fa-chevron-left"></i> 이전
                    </a>
                </li>
                {% else %}
                <li class="page-item disabled">
                    <span class="page-link"><i class="fas fa-chevron-left"></i> 이전</span>
                </li>
                {% endif %}

                <!-- 페이지 번호들 -->
                {% set start_page = [current_page - 2, 1]|max %}
                {% set end_page = [current_page + 2, total_pages]|min %}

                {% if start_page > 1 %}
                <li class="page-item">
                    <a class="page-link" href="?page=1{% if user_filter %}&user_id={{ user_filter }}{% endif %}{% if action_filter %}&action_type={{ action_filter }}{% endif %}">1</a>
                </li>
                {% if start_page > 2 %}
                <li class="page-item disabled">
                    <span class="page-link">...</span>
                </li>
                {% endif %}
                {% endif %}

                {% for page_num in range(start_page, end_page + 1) %}
                <li class="page-item {% if page_num == current_page %}active{% endif %}">
                    <a class="page-link" href="?page={{ page_num }}{% if user_filter %}&user_id={{ user_filter }}{% endif %}{% if action_filter %}&action_type={{ action_filter }}{% endif %}">{{ page_num }}</a>
                </li>
                {% endfor %}

                {% if end_page < total_pages %}
                {% if end_page < total_pages - 1 %}
                <li class="page-item disabled">
                    <span class="page-link">...</span>
                </li>
                {% endif %}
                <li class="page-item">
                    <a class="page-link" href="?page={{ total_pages }}{% if user_filter %}&user_id={{ user_filter }}{% endif %}{% if action_filter %}&action_type={{ action_filter }}{% endif %}">{{ total_pages }}</a>
                </li>
                {% endif %}

                <!-- 다음 페이지 -->
                {% if current_page < total_pages %}
                <li class="page-item">
                    <a class="page-link" href="?page={{ current_page + 1 }}{% if user_filter %}&user_id={{ user_filter }}{% endif %}{% if action_filter %}&action_type={{ action_filter }}{% endif %}">
                        다음 <i class="fas fa-chevron-right"></i>
                    </a>
                </li>
                {% else %}
                <li class="page-item disabled">
                    <span class="page-link">다음 <i class="fas fa-chevron-right"></i></span>
                </li>
                {% endif %}
            </ul>
        </nav>
        {% endif %}
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>