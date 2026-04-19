<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ step }}단계: {{ rcm_info.rcm_name }} - Snowball 내부평가</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Noto+Sans+KR:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-gradient: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
            --glass-bg: rgba(255, 255, 255, 0.95);
            --card-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
        }

        body {
            font-family: 'Inter', 'Noto Sans KR', sans-serif;
            background: #f8fafc;
            color: #1e293b;
            min-height: 100vh;
        }

        .navbar {
            background: var(--glass-bg);
            backdrop-filter: blur(10px);
            border-bottom: 1px solid rgba(226, 232, 240, 0.8);
            padding: 1rem 2rem;
        }

        .step-header {
            background: var(--primary-gradient);
            padding: 4rem 2rem;
            color: white;
            border-bottom-left-radius: 2rem;
            border-bottom-right-radius: 2rem;
            margin-bottom: -2rem;
        }

        .assessment-step-container {
            max-width: 1000px;
            margin: 0 auto;
            position: relative;
            z-index: 10;
        }

        .step-card {
            background: white;
            border-radius: 1.5rem;
            border: none;
            box-shadow: var(--card-shadow);
            overflow: hidden;
            background: var(--glass-bg);
            backdrop-filter: blur(10px);
            margin-bottom: 2rem;
        }

        .card-header {
            background: transparent;
            border-bottom: 1px solid #f1f5f9;
            padding: 1.5rem 2rem;
        }

        .card-body {
            padding: 2.5rem;
        }

        .step-badge {
            background: rgba(255, 255, 255, 0.2);
            padding: 0.5rem 1rem;
            border-radius: 2rem;
            font-weight: 600;
            font-size: 0.875rem;
            margin-bottom: 1rem;
            display: inline-block;
        }

        .btn-primary {
            background: var(--primary-gradient);
            border: none;
            padding: 0.8rem 2rem;
            border-radius: 1rem;
            font-weight: 600;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 15px -3px rgba(99, 102, 241, 0.4);
        }

        .navigation-footer {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 3rem;
            padding-bottom: 4rem;
        }

        .btn-outline-secondary {
            border-radius: 1rem;
            padding: 0.8rem 1.5rem;
            border: 1px solid #e2e8f0;
            color: #64748b;
        }

        .btn-outline-secondary:hover {
            background: #f8fafc;
            border-color: #cbd5e1;
            color: #334155;
        }
    </style>
</head>
<body>
    <nav class="navbar sticky-top">
        <div class="container-fluid">
            <a class="navbar-brand d-flex align-items-center" href="/">
                <img src="/static/logo.png" alt="Snowball" height="30" class="me-2" onerror="this.src='https://via.placeholder.com/30x30?text=S'">
                <span class="fw-bold text-primary">SNOWBALL</span>
            </a>
            <div class="d-flex align-items-center">
                <span class="me-3 text-muted small">
                    <i class="fas fa-user-circle me-1"></i> {{ user_info.user_name }}님
                </span>
                <a href="/logout" class="btn btn-sm btn-outline-danger">로그아웃</a>
            </div>
        </div>
    </nav>

    <div class="step-header">
        <div class="container text-center">
            <span class="step-badge">{{ step }} / 6 단계</span>
            <h1 class="fw-bold mb-2">{{ rcm_info.rcm_name }}</h1>
            <p class="opacity-75">{{ rcm_info.company_name }} | 내부평가 진행</p>
        </div>
    </div>

    <div class="container assessment-step-container">
        <div class="step-card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h4 class="mb-0 fw-bold" id="step_title">{{ step }}단계: 평가 상세 내용</h4>
                <span class="badge bg-soft-info text-info rounded-pill px-3 py-2">
                    <i class="fas fa-clock me-1"></i> 진행 중
                </span>
            </div>
            <div class="card-body">
                <div class="step-content text-center py-5">
                    <div class="mb-4">
                        <i class="fas fa-tools fa-4x text-muted opacity-50 mb-3"></i>
                        <h5 class="fw-bold">이 페이지는 현재 준비 중입니다.</h5>
                        <p class="text-muted">내부평가의 {{ step }}단계를 위한 상세 기능이 곧 구현될 예정입니다.</p>
                    </div>
                    
                    <div class="alert alert-info border-0 shadow-sm d-inline-block px-4">
                        <i class="fas fa-info-circle me-2"></i>
                        설계평가(1단계)와 운영평가(2단계)의 핵심 기능은 상세 현황 페이지에서 직접 접근할 수 있습니다.
                    </div>
                </div>
            </div>
        </div>

        <div class="navigation-footer">
            <button class="btn btn-outline-secondary" onclick="history.back()">
                <i class="fas fa-arrow-left me-2"></i> 이전으로
            </button>
            <div class="d-flex gap-2">
                <a href="/link8/{{ rcm_info.rcm_id }}" class="btn btn-outline-primary">
                    <i class="fas fa-list me-2"></i> 목록 보기
                </a>
                <button class="btn btn-primary" onclick="alert('데이터가 저장되었습니다.')">
                    <i class="fas fa-save me-2"></i> 확인 및 계속
                </button>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
