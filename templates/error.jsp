<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball - 오류</title>
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <style>
        .error-container {
            max-width: 600px;
            margin: 100px auto;
            padding: 40px;
            text-align: center;
        }
        .error-icon {
            font-size: 5rem;
            color: #dc3545;
            margin-bottom: 20px;
        }
        .error-title {
            font-size: 2rem;
            font-weight: 700;
            color: var(--text-color);
            margin-bottom: 15px;
        }
        .error-message {
            font-size: 1.1rem;
            color: #6c757d;
            margin-bottom: 30px;
            line-height: 1.6;
        }
        .error-actions {
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .error-btn {
            padding: 12px 30px;
            border-radius: 8px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s;
        }
        .error-btn-primary {
            background: var(--primary-color);
            color: white;
        }
        .error-btn-primary:hover {
            background: var(--secondary-color);
            color: white;
            transform: translateY(-2px);
        }
        .error-btn-secondary {
            background: #6c757d;
            color: white;
        }
        .error-btn-secondary:hover {
            background: #5a6268;
            color: white;
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    {% include 'navi.jsp' %}

    <div class="error-container">
        <div class="error-icon">
            <i class="fas fa-exclamation-triangle"></i>
        </div>
        <h1 class="error-title">{{ error_title or '오류가 발생했습니다' }}</h1>
        <p class="error-message">{{ error_message or '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.' }}</p>

        <div class="error-actions">
            {% if return_url %}
            <a href="{{ return_url }}" class="error-btn error-btn-primary">
                <i class="fas fa-redo me-2"></i>다시 시도
            </a>
            {% endif %}
            <a href="/" class="error-btn error-btn-secondary">
                <i class="fas fa-home me-2"></i>메인으로 이동
            </a>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
