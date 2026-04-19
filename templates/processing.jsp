<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>Snowball - 작업 진행 중</title>
    <!-- 다크모드 FOUC 방지 -->
    <script>(function(){var t=localStorage.getItem('snowball-theme')||'light';document.documentElement.setAttribute('data-bs-theme',t);})();</script>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="shortcut icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
</head>

<body class="processing-page"
    style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; margin: 0;">
    {% include 'navi.jsp' %}
    <div class="processing-container text-center mt-5">

        <div class="blacksmith-container">
            <div class="anvil"></div>
            <div class="hammer">🔨</div>
            <div class="sparks">
                <div class="spark"></div>
                <div class="spark"></div>
                <div class="spark"></div>
                <div class="spark"></div>
            </div>
        </div>

        <h2 class="mb-4">✨ AI 검토 및 문서 생성 중입니다</h2>

        <div class="processing-message">
            <p>📋 인터뷰 내용을 분석하고 ITGC 설계평가 문서를 생성하고 있습니다.</p>
            <p class="text-muted">📧 완료되면 <strong>{{ user_email }}</strong>로 결과를 전송해 드리겠습니다.</p>
        </div>

        <div class="progress-container">
            <div class="progress mb-3">
                <div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar" id="progressBar"
                    style="width: 0%" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100">
                    <span id="progressText">0%</span>
                </div>
            </div>
            <div id="currentTask" class="text-muted">🔄 AI 검토를 준비하고 있습니다...</div>
        </div>

        <div class="alert alert-info mt-4">
            <strong>⏳ 잠시만 기다려 주세요.</strong><br>
            ⏱️ 처리 시간은 인터뷰 내용에 따라 다를 수 있습니다.<br>
            ⚠️ 화면을 닫지 마세요. 화면을 닫을 경우 메일 전송이 안될 수 있습니다.
        </div>

        <a href="/" class="btn btn-primary mt-3" id="mainPageBtn" style="display: none;">🏠 메인으로 이동</a>
    </div>

    <script>
        let progressInterval;
        const taskId = '{{ task_id }}'; // 서버에서 전달된 task_id

        // 진행률 업데이트 함수
        function updateProgress() {
            console.log(`🔄 Requesting progress update for task ${taskId}...`);
            fetch('{{ url_for("link2.get_progress") }}?task_id=' + taskId)
                .then(response => {
                    if (!response.ok) {
                        throw new Error(`Network response was not ok: ${response.statusText}`);
                    }
                    return response.json();
                })
                .then(data => {
                    console.log('📊 Progress data:', data);
                    if (data.error) {
                        console.error('Error from server:', data.error);
                        clearInterval(progressInterval);
                        return;
                    }

                    const progressBar = document.getElementById('progressBar');
                    const progressText = document.getElementById('progressText');
                    const currentTask = document.getElementById('currentTask');

                    // 진행률 업데이트 (안전한 타입 체크 추가)
                    const percentage = parseInt(data.percentage) || 0;
                    const currentTaskText = data.current_task || 'AI 검토를 준비하고 있습니다...';

                    progressBar.style.width = percentage + '%';
                    progressBar.setAttribute('aria-valuenow', percentage);
                    progressText.textContent = percentage + '%';
                    currentTask.textContent = currentTaskText;

                    // 브라우저 제목도 업데이트
                    document.title = `작업 진행 중 (${percentage}%)`;

                    // 처리 완료 또는 처리 중이 아닐 때 폴링 중단
                    if (!data.is_processing || percentage >= 100) {
                        console.log('🛑 Stopping progress polling.');
                        clearInterval(progressInterval);
                    }
                })
                .catch(error => {
                    console.error('❌ Progress update error:', error);
                    // 네트워크 오류 시 재시도 카운터 추가
                    if (!window.retryCount) window.retryCount = 0;
                    window.retryCount++;

                    if (window.retryCount >= 5) {
                        console.log('❌ Too many retries, stopping progress polling.');
                        clearInterval(progressInterval);
                        document.getElementById('currentTask').textContent = '네트워크 오류로 진행상태를 확인할 수 없습니다.';
                    }
                });
        }

        // 페이지 로드 후 자동으로 작업 시작
        document.addEventListener('DOMContentLoaded', function () {
            console.log(`🚀 Page loaded, starting process for task ${taskId}...`);

            // 즉시 한 번 호출하여 초기 상태 표시
            updateProgress();
            // 진행률 폴링 시작 (1.5초마다)
            progressInterval = setInterval(updateProgress, 1500);

            // 실제 작업을 시작하는 AJAX 요청
            var processXhr = new XMLHttpRequest();
            processXhr.open('POST', '{{ url_for("link2.process_interview") }}', true);
            processXhr.setRequestHeader('Content-Type', 'application/json');
            processXhr.onreadystatechange = function () {
                if (processXhr.readyState === 4) {
                    // 최종 상태를 한 번 더 업데이트하여 100%를 확실히 표시
                    updateProgress();
                    clearInterval(progressInterval);

                    if (processXhr.status === 200) {
                        try {
                            var data = JSON.parse(processXhr.responseText);
                            if (data.success) {
                                document.title = '작업 완료';
                                document.querySelector('h2').innerHTML = '✅ AI 검토 및 문서 생성이 완료되었습니다';
                                document.querySelector('.processing-message').innerHTML =
                                    '<p class="text-success"><strong>🎉 ITGC 설계평가 문서가 성공적으로 생성되어 메일로 전송되었습니다!</strong></p>' +
                                    '<p>📮 메일함을 확인해 주세요.</p>';
                                document.getElementById('progressBar').style.width = '100%';
                                document.getElementById('progressText').textContent = '100%';
                                document.getElementById('currentTask').textContent = '작업 완료!';
                            } else {
                                document.title = '작업 오류';
                                document.querySelector('h2').innerHTML = '❌ 처리 중 오류가 발생했습니다';
                                document.querySelector('.processing-message').innerHTML =
                                    '<p class="text-danger"><strong>⚠️ 처리 중 오류가 발생했습니다.</strong></p>' +
                                    '<p>🔧 ' + (data.error || '알 수 없는 오류가 발생했습니다.') + '</p>';
                            }
                        } catch (e) {
                            document.title = '처리 오류';
                            document.querySelector('h2').innerHTML = '❌ 응답 처리 중 오류가 발생했습니다';
                            document.querySelector('.processing-message').innerHTML =
                                '<p class="text-danger"><strong>⚠️ 서버 응답 처리 중 오류가 발생했습니다.</strong></p>';
                        }
                    } else {
                        document.title = '네트워크 오류';
                        document.querySelector('h2').innerHTML = '🌐 네트워크 오류 발생';
                        document.querySelector('.processing-message').innerHTML =
                            '<p class="text-danger"><strong>📡 서버와 통신 중 오류가 발생했습니다.</strong></p>';
                    }
                    // 공통 UI 처리
                    document.querySelector('.blacksmith-container').style.display = 'none'; // 애니메이션 숨기기
                    document.querySelector('.alert-info').style.display = 'none';
                    document.getElementById('mainPageBtn').style.display = 'inline-block';
                }
            };
            // 요청 본문에 task_id 포함
            processXhr.send(JSON.stringify({ task_id: taskId }));
        });
    </script>
</body>

</html>