<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>Snowball - AI 검토 옵션 선택</title>
    <!-- 다크모드 FOUC 방지 -->
    <script>(function(){var t=localStorage.getItem('snowball-theme')||'light';document.documentElement.setAttribute('data-bs-theme',t);})();</script>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .ai-option-card {
            cursor: pointer;
            transition: all 0.3s ease;
            border: 2px solid transparent;
        }

        .ai-option-card:hover {
            border-color: #007bff;
            box-shadow: 0 4px 8px rgba(0, 123, 255, 0.3);
        }

        .ai-option-card.selected {
            border-color: #007bff;
            background-color: rgba(0, 123, 255, 0.1);
            box-shadow: 0 4px 12px rgba(0, 123, 255, 0.4);
        }

        #emailInput.border-primary {
            border-color: #007bff !important;
            box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
        }

        .btn-close {
            font-size: 0.8rem;
        }
    </style>
</head>

<body>
    {% include 'navi.jsp' %}
    <div class="container text-center mt-5">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card shadow-lg">
                    <div class="card-header bg-primary text-white">
                        <h3><i class="fas fa-check-circle"></i> 인터뷰가 완료되었습니다!</h3>
                    </div>
                    <div class="card-body p-4">
                        <div class="alert alert-success mb-4">
                            <h5><i class="fas fa-clipboard-check"></i> 모든 질문에 답변해 주셔서 감사합니다</h5>
                            <p class="mb-0">이제 ITGC 설계평가 문서를 생성하여 메일로 전송해 드리겠습니다.</p>
                        </div>

                        <div class="mb-4">
                            <h5 class="mb-3"><i class="fas fa-robot"></i> AI 검토 옵션</h5>
                            <p class="text-muted">AI가 답변을 분석하여 더 정확하고 완성도 높은 문서를 생성할 수 있습니다.</p>

                            <!-- AI 검토 범위 안내 -->
                            {% if is_logged_in %}
                            <div class="alert alert-success">
                                <i class="fas fa-user-check"></i> <strong>로그인 사용자</strong> - AI가 <strong>전체 통제</strong>를
                                검토합니다
                                <br><small class="text-muted">APD, PC, CO 카테고리의 모든 통제 항목 (총 25개)</small>
                            </div>
                            {% else %}
                            <div class="alert alert-warning">
                                <i class="fas fa-user"></i> <strong>비회원 사용자</strong> - AI가 <strong>핵심 통제 3개</strong>만
                                검토합니다
                                <br><small class="text-muted">APD01 (Application 권한 승인), APD02 (Application 권한 제거),
                                    APD03 (Application 권한 검토)</small>
                                <br><small><i class="fas fa-info-circle text-info"></i> 회원가입 시 전체 통제 검토가 가능합니다</small>
                            </div>
                            {% endif %}
                        </div>

                        <div class="row g-3">
                            <div class="col-md-6">
                                <div class="card h-100 ai-option-card" data-option="yes">
                                    <div class="card-body d-flex flex-column justify-content-center">
                                        <i class="fas fa-brain fa-3x text-primary mb-3"></i>
                                        <h5 class="card-title">AI 검토 사용</h5>
                                        <ul class="list-unstyled text-start small mb-3">
                                            <li><i class="fas fa-check text-success me-2"></i>답변 내용 검토 및 개선</li>
                                            <li><i class="fas fa-check text-success me-2"></i>문장 다듬기 및 문법 교정</li>
                                            <li><i class="fas fa-check text-success me-2"></i>전문적인 검토 의견 제공</li>
                                        </ul>
                                        <p class="text-warning small"><i class="fas fa-clock"></i> <strong>처리 시간: 약 1-2분
                                                소요됩니다</strong></p>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="card h-100 ai-option-card" data-option="no">
                                    <div class="card-body d-flex flex-column justify-content-center">
                                        <i class="fas fa-file-alt fa-3x text-secondary mb-3"></i>
                                        <h5 class="card-title">기본 문서 생성</h5>
                                        <ul class="list-unstyled text-start small mb-3">
                                            <li><i class="fas fa-check text-success me-2"></i>빠른 문서 생성</li>
                                            <li><i class="fas fa-check text-success me-2"></i>입력한 답변 그대로 반영</li>
                                            <li><i class="fas fa-check text-success me-2"></i>즉시 처리</li>
                                            <li><i class="fas fa-times text-muted me-2"></i>AI 검토 없음</li>
                                        </ul>
                                        <p class="text-muted small">처리 시간: 30초 이내</p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="mt-4">
                            <form id="aiReviewForm" method="POST"
                                action="{{ url_for('link2.process_with_ai_option') }}">
                                <input type="hidden" name="csrf_token" value="{{ csrf_token() }}" />
                                <input type="hidden" name="enable_ai_review" id="enableAiReview" value="">
                                <button type="submit" id="proceedBtn" class="btn btn-primary btn-lg disabled" disabled>
                                    <i class="fas fa-arrow-right"></i> 진행
                                </button>
                            </form>
                        </div>

                        <div class="mt-3">
                            <div class="card">
                                <div class="card-body">
                                    <div class="row align-items-center">
                                        <div class="col-md-8">
                                            <label class="form-label mb-1">
                                                <i class="fas fa-envelope"></i> 결과 문서 전송 이메일
                                            </label>
                                            <div class="input-group">
                                                <input type="email" class="form-control" id="emailInput"
                                                    value="{{ user_email }}" readonly>
                                                <button class="btn btn-outline-secondary" type="button"
                                                    id="editEmailBtn">
                                                    <i class="fas fa-edit"></i> 수정
                                                </button>
                                            </div>
                                        </div>
                                        <div class="col-md-4 text-end">
                                            <button class="btn btn-success d-none" type="button" id="saveEmailBtn">
                                                <i class="fas fa-check"></i> 저장
                                            </button>
                                            <button class="btn btn-secondary d-none ms-1" type="button"
                                                id="cancelEmailBtn">
                                                <i class="fas fa-times"></i> 취소
                                            </button>
                                        </div>
                                    </div>
                                    <small class="text-muted mt-1 d-block">
                                        <i class="fas fa-info-circle"></i> 생성된 ITGC 설계평가 문서가 이 이메일로 전송됩니다.
                                    </small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>



    <script>
        document.addEventListener('DOMContentLoaded', function () {
            const optionCards = document.querySelectorAll('.ai-option-card');
            const proceedBtn = document.getElementById('proceedBtn');
            const enableAiReviewInput = document.getElementById('enableAiReview');

            // AI 검토 옵션 선택 로직
            optionCards.forEach(card => {
                card.addEventListener('click', function () {
                    // 모든 카드에서 selected 클래스 제거
                    optionCards.forEach(c => c.classList.remove('selected'));

                    // 클릭된 카드에 selected 클래스 추가
                    this.classList.add('selected');

                    // 선택된 옵션 값 설정
                    const option = this.getAttribute('data-option');
                    enableAiReviewInput.value = option === 'yes' ? 'true' : 'false';

                    // 버튼 활성화
                    proceedBtn.classList.remove('disabled');
                    proceedBtn.disabled = false;

                    // 버튼 텍스트 업데이트
                    if (option === 'yes') {
                        proceedBtn.innerHTML = '<i class="fas fa-brain"></i> AI 검토 진행';
                    } else {
                        proceedBtn.innerHTML = '<i class="fas fa-file-alt"></i> 기본 생성 진행';
                    }
                });
            });

            // 이메일 수정 기능
            const emailInput = document.getElementById('emailInput');
            const editEmailBtn = document.getElementById('editEmailBtn');
            const saveEmailBtn = document.getElementById('saveEmailBtn');
            const cancelEmailBtn = document.getElementById('cancelEmailBtn');
            let originalEmail = emailInput.value;

            // 수정 버튼 클릭
            editEmailBtn.addEventListener('click', function () {
                originalEmail = emailInput.value; // 원본 이메일 저장
                emailInput.readOnly = false;
                emailInput.focus();
                emailInput.classList.add('border-primary');

                // 버튼 표시/숨김
                editEmailBtn.classList.add('d-none');
                saveEmailBtn.classList.remove('d-none');
                cancelEmailBtn.classList.remove('d-none');
            });

            // 저장 버튼 클릭
            saveEmailBtn.addEventListener('click', function () {
                const newEmail = emailInput.value.trim();

                // 이메일 유효성 검사
                if (!validateEmail(newEmail)) {
                    alert('올바른 이메일 주소를 입력해주세요.');
                    emailInput.focus();
                    return;
                }

                // 서버에 이메일 업데이트 요청
                updateEmailInSession(newEmail);
            });

            // 취소 버튼 클릭
            cancelEmailBtn.addEventListener('click', function () {
                emailInput.value = originalEmail; // 원본으로 복원
                resetEmailEditMode();
            });

            // Enter 키로 저장
            emailInput.addEventListener('keypress', function (e) {
                if (e.key === 'Enter') {
                    saveEmailBtn.click();
                }
            });

            // ESC 키로 취소
            emailInput.addEventListener('keydown', function (e) {
                if (e.key === 'Escape') {
                    cancelEmailBtn.click();
                }
            });

            // 이메일 수정 모드 리셋
            function resetEmailEditMode() {
                emailInput.readOnly = true;
                emailInput.classList.remove('border-primary');

                editEmailBtn.classList.remove('d-none');
                saveEmailBtn.classList.add('d-none');
                cancelEmailBtn.classList.add('d-none');
            }

            // 이메일 유효성 검사
            function validateEmail(email) {
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                return emailRegex.test(email);
            }

            // 서버에 이메일 업데이트
            function updateEmailInSession(newEmail) {
                fetch('{{ url_for("link2.update_session_email") }}', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    credentials: 'same-origin',
                    body: JSON.stringify({ email: newEmail })
                })
                    .then(response => response.json())
                    .then(result => {
                        if (result.success) {
                            resetEmailEditMode();
                            // 성공 토스트 표시
                            showToast('이메일이 성공적으로 변경되었습니다.', 'success');
                        } else {
                            alert('이메일 변경에 실패했습니다: ' + result.message);
                        }
                    })
                    .catch(error => {
                        console.error('이메일 업데이트 오류:', error);
                        alert('이메일 변경 중 오류가 발생했습니다.');
                    });
            }

            // 간단한 토스트 알림
            function showToast(message, type = 'success') {
                const toastDiv = document.createElement('div');
                toastDiv.className = `alert alert-${type} position-fixed`;
                toastDiv.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
                toastDiv.innerHTML = `
                    <i class="fas fa-check-circle"></i> ${message}
                    <button type="button" class="btn-close float-end" onclick="this.parentElement.remove()"></button>
                `;
                document.body.appendChild(toastDiv);

                setTimeout(() => {
                    if (toastDiv.parentElement) {
                        toastDiv.remove();
                    }
                }, 3000);
            }
        });
    </script>
</body>

</html>