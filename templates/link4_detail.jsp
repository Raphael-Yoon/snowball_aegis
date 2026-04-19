<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball - 교육 영상</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" rel="stylesheet">
    		<link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
		<link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
</head>
<body>
    <div class="container mt-3">
        {% if img_url %}
        <!-- 상단 이미지+텍스트 카드 -->
        <div class="card mb-3" id="info-card">
            <div class="card-body">
                <h5 class="card-title" id="info-title">{{ title }}</h5>
                <p class="card-text" id="info-desc">{{ desc }}</p>
            </div>
            <img id="info-img" src="{{ img_url }}" class="card-img" alt="{{ title }}">
        </div>
        {% endif %}
        <!-- 유튜브 영상 카드 -->
        <div class="card">
            <div class="card-body">
                <h5 class="card-title mb-3" id="video-title">{{ title }} 교육 영상</h5>
                <div class="ratio ratio-16x9">
                    <iframe id="youtube-frame" src="{{ youtube_url }}" title="교육 영상" allowfullscreen></iframe>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html> 