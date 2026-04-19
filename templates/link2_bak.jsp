<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball - 인터뷰/설계평가</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <!-- CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css')}}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css')}}" rel="stylesheet">
</head>

<body>
    {% include 'navi.jsp' %}

    <div class="container mt-4">
        <!-- 진행률 표시 -->
        <div class="progress">
            <div class="progress-bar" role="progressbar"
                style="width: {{ (current_index + 1) / question_count * 100 }}%" aria-valuenow="{{ current_index + 1 }}"
                aria-valuemin="0" aria-valuemax="{{ question_count }}">
                {{ "%.1f"|format((current_index + 1) / question_count * 100) }}%
            </div>
        </div>

        <!-- 섹션 제목 -->
        <div class="text-center mt-3">
            <h1 class="section-title">
                {% if actual_question_number %}
                {% set q_num = actual_question_number - 1 %}
                {% else %}
                {% set q_num = current_index %}
                {% endif %}

                {% if q_num >= 0 and q_num <= 5 %} <i class="fas fa-server"></i> 공통사항
                    {% elif q_num >= 6 and q_num <= 32 %} <i class="fas fa-lock"></i> APD(Access to Program & Data)
                        {% elif q_num >= 33 and q_num <= 39 %} <i class="fas fa-laptop-code"></i> PC(Program Change)
                            {% elif q_num >= 40 and q_num <= 49 %} <i class="fas fa-cogs"></i> CO(Computer Operation)
                                {% else %}
                                <i class="fas fa-check-circle"></i> 모든 질문이 완료되었습니다.
                                {% endif %}
            </h1>
        </div>

        <div class="text-center mt-4">
            {% if remote_addr == '127.0.0.1' or (user_info and user_info.get('admin_flag') == 'Y') %}
            <button type="button" class="btn btn-outline-secondary me-2"
                onclick="fillSample({{ actual_question_number - 1 if actual_question_number else current_index }}, {{ current_index }})">
                <i class="fas fa-magic"></i> 샘플입력
            </button>
            <button type="button" class="btn btn-outline-warning me-2"
                onclick="fillSkipSample({{ actual_question_number - 1 if actual_question_number else current_index }}, {{ current_index }})">
                <i class="fas fa-fast-forward"></i> 스킵샘플
            </button>
            {% endif %}
        </div>

        <!-- 질문 폼 -->
        <form action="{{ url_for('link2.link2') }}" method="post">
            <input type="hidden" name="csrf_token" value="{{ csrf_token() }}" />
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">
                        <i class="fas fa-question-circle"></i>
                        {% if actual_question_number %}
                        질문 {{ actual_question_number }}/52
                        {% else %}
                        질문 {{ current_index + 1 }}/52
                        {% endif %}
                    </h5>
                    <p class="card-text">{{ question.text }}</p>
                    <div class="mb-3">
                        <!-- 입력 필드 -->
                        {% if question.answer_type == '0' %}
                        <select class="form-select" name="a0" required>
                            <option value="">담당자를 선택하세요</option>
                            {# {% for i in range(0, users|length, 3) %}
                            <option value="{{ users[i+2] }}" {% if answer[0]==users[i+2] %}selected{% endif %}>{{
                                users[i] }} - {{ users[i+1] }}</option>
                            {% endfor %} #}
                        </select>
                        <!-- 첫 번째 질문(이메일 입력) -->
                        {% if current_index == 0 %}
                        <div class="mt-2">
                            <input type="text" class="form-control{% if is_logged_in %} bg-light{% endif %}"
                                name="a0_text" placeholder="e-Mail 주소를 입력하세요" value="{{ answer[0] }}" {% if is_logged_in
                                %}readonly{% endif %} />
                            {% if is_logged_in %}
                            <small class="form-text text-muted">
                                <i class="fas fa-lock me-1"></i>로그인된 계정의 이메일이 자동으로 사용됩니다.
                            </small>
                            {% endif %}
                        </div>
                        {% endif %}
                        {% elif question.answer_type == '2' %}
                        {% if current_index == 0 %}
                        <!-- 첫 번째 질문(이메일 입력) -->
                        <input type="text" class="form-control{% if is_logged_in %} bg-light{% endif %}"
                            name="a{{ current_index }}" required
                            placeholder="{{ question.text_help if question.text_help else 'e-Mail 주소를 입력하세요' }}"
                            value="{{ answer[actual_question_number - 1] }}" {% if is_logged_in %}readonly{% endif %}>
                        {% if is_logged_in %}
                        <small class="form-text text-muted">
                            <i class="fas fa-lock me-1"></i>로그인된 계정의 이메일이 자동으로 사용됩니다.
                        </small>
                        {% endif %}
                        {% else %}
                        <!-- 일반 텍스트 입력 -->
                        <input type="text" class="form-control" name="a{{ current_index }}" required
                            placeholder="{{ question.text_help if question.text_help else '' }}"
                            value="{{ answer[actual_question_number - 1] }}">
                        {% endif %}
                        {% elif question.answer_type == '3' %}
                        <label class="form-check">
                            <input type="radio" class="form-check-input" name="a{{ current_index }}" value="Y"
                                id="yes_{{ current_index }}" required
                                onchange="toggleTextInput({{ current_index }})"
                                {% if answer[actual_question_number - 1]=='Y' %}checked{% endif %}>
                            <span class="form-check-label">예</span>
                        </label>
                        <input type="text" class="form-control mt-2" name="a{{ current_index }}_1"
                            id="text_input_{{ current_index }}"
                            data-orig-placeholder="{{ question.text_help if question.text_help else '제품명을 입력하세요' }}"
                            placeholder="{{ '' if answer[actual_question_number - 1] == 'N' else (question.text_help if question.text_help else '제품명을 입력하세요') }}"
                            value="{{ textarea_answer[actual_question_number - 1] }}"
                            {% if answer[actual_question_number - 1] == 'N' %}disabled style="cursor:not-allowed;background-color:#e9ecef;"{% elif answer[actual_question_number - 1] == 'Y' %}required{% endif %}>
                        <label class="form-check mt-2">
                            <input type="radio" class="form-check-input" name="a{{ current_index }}" value="N" required
                                onchange="toggleTextInput({{ current_index }})"
                                {% if answer[actual_question_number - 1]=='N' %}checked{% endif %}>
                            <span class="form-check-label">아니요</span>
                        </label>
                        {% elif question.answer_type == '4' %}
                        <label class="form-check">
                            <input type="radio" class="form-check-input" name="a{{ current_index }}" value="Y" required
                                onchange="toggleTextarea({{ current_index }})" {% if answer[actual_question_number - 1]=='Y'
                                %}checked{% endif %}>
                            <span class="form-check-label">예</span>
                        </label>
                        <textarea class="form-control mt-2" name="a{{ current_index }}_1"
                            id="textarea_{{ current_index }}"
                            placeholder="{{ question.text_help if question.text_help else '관련 절차를 입력하세요.' }}" rows="5"
                            {% if answer[actual_question_number - 1] !='Y' %}readonly{% endif %} {% if answer[actual_question_number - 1]=='Y'
                            %}required{% endif %} onclick="selectYesAndEnableTextarea({{ current_index }})"
                            style="cursor: {% if answer[actual_question_number - 1]=='N' %}not-allowed{% else %}pointer{% endif %}; {% if answer[actual_question_number - 1]=='N' %}background-color:#e9ecef;{% endif %}">{{ textarea_answer[actual_question_number - 1] }}</textarea>
                        <label class="form-check">
                            <input type="radio" class="form-check-input" name="a{{ current_index }}" value="N" required
                                onchange="toggleTextarea({{ current_index }})" {% if answer[actual_question_number - 1]=='N'
                                %}checked{% endif %}>
                            <span class="form-check-label">아니요</span>
                        </label>
                        {% elif question.answer_type == '5' %}
                        <textarea class="form-control" name="a{{ current_index }}" required
                            placeholder="{{ question.text_help if question.text_help else '관련 절차를 입력하세요.' }}"
                            rows="5">{{ answer[actual_question_number - 1] }}</textarea>
                        {% elif question.answer_type == '1' %}
                        <label class="form-check">
                            <input type="radio" class="form-check-input" name="a{{ current_index }}" value="Y" required
                                {% if answer[actual_question_number - 1]=='Y' %}checked{% endif %}>
                            <span class="form-check-label">예</span>
                        </label>
                        <label class="form-check">
                            <input type="radio" class="form-check-input" name="a{{ current_index }}" value="N" {% if
                                answer[actual_question_number - 1]=='N' %}checked{% endif %}>
                            <span class="form-check-label">아니요</span>
                        </label>
                        {% elif question.answer_type == '6' %}
                        {% for option in question.text_help.split('|') %}
                        <label class="form-check">
                            <input type="radio" class="form-check-input" name="a{{ current_index }}"
                                value="{{ option }}" required {% if answer[actual_question_number - 1]==option %}checked{% endif %}>
                            <span class="form-check-label">{{ option }}</span>
                        </label>
                        {% endfor %}
                        {% else %}
                        <input type="text" class="form-control" name="a{{ current_index }}"
                            value="{{ answer[actual_question_number - 1] }}">
                        {% endif %}
                    </div>
                </div>
            </div>

            <!-- 도움말: s_questions의 help 필드를 활용하여 출력 -->
            {# 아래는 snowball.py의 s_questions 각 질문 딕셔너리의 help 필드를 그대로 출력합니다. #}
            {% if question.help %}
            <div class="help-text">
                <i class="fas fa-info-circle me-2"></i>
                {{ question.help|safe }}
            </div>
            {% endif %}
            <!-- 제출 버튼 -->
            <div class="text-center mt-4">
                {% if current_index > 0 %}
                <a href="{{ url_for('link2.link2_prev') }}" class="btn btn-secondary me-2">
                    <i class="fas fa-arrow-left"></i>
                    이전
                </a>
                {% endif %}
                <button type="submit" class="btn btn-primary" id="submitBtn">
                    <i class="fas fa-arrow-right"></i>
                    {% if current_index + 1 == question_count %}제출{% else %}다음{% endif %}
                </button>
            </div>
        </form>
    </div>

    <!-- 완료 모달 -->
    <div class="modal fade" id="completeModal" tabindex="-1" aria-labelledby="completeModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="completeModalLabel">알림</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    완료
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-primary" id="modalConfirmBtn">확인</button>
                </div>
            </div>
        </div>
    </div>

    <!-- 메일 전송 안내 모달 (43번 질문 전용) -->
    <div class="modal fade" id="mailModal" tabindex="-1" aria-labelledby="mailModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="mailModalLabel">알림</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    곧 메일이 전송됩니다.
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-primary" id="mailModalConfirmBtn">확인</button>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function selectYes(questionNumber) {
            document.getElementById("yes_" + questionNumber).checked = true;
        }

        function toggleTextInput(questionNumber) {
            const textInput = document.getElementById(`text_input_${questionNumber}`);
            const yesRadio = document.querySelector(`input[name="a${questionNumber}"][value="Y"]`);
            const noRadio = document.querySelector(`input[name="a${questionNumber}"][value="N"]`);
            if (!textInput || !yesRadio || !noRadio) return;
            if (yesRadio.checked) {
                textInput.removeAttribute('disabled');
                textInput.required = true;
                textInput.style.cursor = 'text';
                textInput.style.backgroundColor = '';
                textInput.placeholder = textInput.dataset.origPlaceholder || '';
            } else if (noRadio.checked) {
                if (!textInput.dataset.origPlaceholder) {
                    textInput.dataset.origPlaceholder = textInput.placeholder;
                }
                textInput.setAttribute('disabled', true);
                textInput.value = '';
                textInput.required = false;
                textInput.style.cursor = 'not-allowed';
                textInput.style.backgroundColor = '#e9ecef';
                textInput.placeholder = '';
            }
        }

        function selectYesAndEnableTextarea(questionNumber) {
            console.log('selectYesAndEnableTextarea called for question:', questionNumber);
            // '예' 라디오 버튼 찾기
            const yesRadio = document.querySelector(`input[name="a${questionNumber}"][value="Y"]`);
            if (!yesRadio) {
                console.error('Yes radio button not found for question:', questionNumber);
                return;
            }
            // textarea 찾기
            const textarea = document.getElementById(`textarea_${questionNumber}`);
            if (!textarea) {
                console.error('Textarea not found for question:', questionNumber);
                return;
            }
            // '예' 선택
            yesRadio.checked = true;
            console.log('Yes radio button checked');
            // textarea 활성화
            textarea.removeAttribute('readonly');
            textarea.required = true;
            console.log('Textarea enabled and required');
            // change 이벤트 발생
            const event = new Event('change', { bubbles: true });
            yesRadio.dispatchEvent(event);
        }

        function toggleTextarea(questionNumber) {
            console.log('toggleTextarea called for question:', questionNumber);
            const textarea = document.getElementById(`textarea_${questionNumber}`);
            const yesRadio = document.querySelector(`input[name="a${questionNumber}"][value="Y"]`);
            const noRadio = document.querySelector(`input[name="a${questionNumber}"][value="N"]`);
            if (!textarea || !yesRadio || !noRadio) {
                console.error('Required elements not found for question:', questionNumber);
                return;
            }
            if (yesRadio.checked) {
                textarea.removeAttribute('readonly');
                textarea.required = true;
                textarea.style.cursor = 'text';
                textarea.style.backgroundColor = '';
                console.log('Textarea enabled and required');
            } else if (noRadio.checked) {
                textarea.setAttribute('readonly', true);
                textarea.value = '';
                textarea.required = false;
                textarea.style.cursor = 'not-allowed';
                textarea.style.backgroundColor = '#e9ecef';
                console.log('Textarea disabled and cleared');
            }
        }

        // 라디오 버튼 라벨 클릭 이벤트 처리
        document.addEventListener('DOMContentLoaded', function () {
            // 모든 라디오 버튼 라벨에 클릭 이벤트 추가
            const radioLabels = document.querySelectorAll('.form-check-label');

            radioLabels.forEach(function (label) {
                label.addEventListener('click', function (e) {
                    // 라벨에 연결된 라디오 버튼 찾기
                    const radioId = this.getAttribute('for');
                    if (radioId) {
                        const radio = document.getElementById(radioId);
                        if (radio) {
                            // 라디오 버튼 선택
                            radio.checked = true;

                            // 이벤트 발생 (폼 제출 시 값이 전송되도록)
                            const event = new Event('change', { bubbles: true });
                            radio.dispatchEvent(event);
                        }
                    }
                });
            });
        });

        function fillSample(questionNumber, currentIndex) {
            console.log(`[SAMPLE] fillSample 호출됨 - questionNumber: ${questionNumber}, currentIndex: ${currentIndex}`);
            // 질문별 샘플값 정의
            const samples = {
                0: { type: 'text', value: 'snowball1566@gmail.com' }, // 이메일
                1: { type: 'text', value: 'SAP ERP' }, // 시스템 이름
                2: { type: 'radio_text', radio: 'Y', text: 'SAP S/4HANA' }, // 상용 SW
                3: { type: 'radio', value: 'Y' }, // Cloud 사용 여부
                4: { type: 'radio', value: 'IaaS' }, // Cloud 종류 (IaaS로 해야 질문이 안 끊김)
                5: { type: 'radio', value: 'N' }, // SOC1 Report (N으로 해야 모든 질문 노출)
                6: { type: 'radio', value: 'Y' }, // 권한부여 이력
                7: { type: 'radio', value: 'Y' }, // 권한회수 이력
                8: { type: 'radio', value: 'Y' },                                                        // 개인별 발급(Y) → Q9 스킵, APD01~APD03 절차 표시
                // 9: apd15_shared_mgmt - APD15=Y 시 자동 스킵
                10: { type: 'radio_textarea', radio: 'Y', textarea: 'ITSM 승인 절차 준수' },            // 권한 신청 절차
                11: { type: 'radio_textarea', radio: 'Y', textarea: '인사 이동 발생 시 즉시 회수' },   // 권한 회수 절차
                12: { type: 'radio_textarea', radio: 'Y', textarea: '퇴사 즉시 계정 잠금 처리' },     // 퇴사자 절차
                13: { type: 'textarea', value: 'IT운영팀 김책임, 관리자' },                            // App 관리자
                14: { type: 'radio_textarea', radio: 'Y', textarea: '매 분기 권한 적정성 점검 수행' }, // 모니터링
                15: { type: 'textarea', value: '8자리 이상, 90일 주기 변경' },                        // 패스워드 정책
                16: { type: 'radio', value: 'Y' }, // DB 접속 가능 여부
                17: { type: 'radio', value: 'Y' }, // 데이터 변경 이력 기록
                18: { type: 'radio_textarea', radio: 'Y', textarea: 'DBA 승인 후 쿼리 수행' }, // 데이터 변경 절차
                19: { type: 'textarea', value: 'IT운영팀 이수석, DBA' }, // 데이터 변경 권한자
                20: { type: 'text', value: 'Oracle 19c' }, // DB 종류
                21: { type: 'radio_text', radio: 'Y', text: 'Hiware' }, // DB 접근제어
                22: { type: 'radio', value: 'Y' }, // DB 권한 이력
                23: { type: 'radio_textarea', radio: 'Y', textarea: 'DB 접속은 ITSM 승인이 필수입니다' }, // DB 권한 절차
                24: { type: 'textarea', value: 'IT팀 박책임, DBA' }, // DB 관리자
                25: { type: 'textarea', value: '10자리 이상, 특수문자 포함' }, // DB 패스워드
                26: { type: 'radio', value: 'Y' }, // OS 접속 가능 여부
                27: { type: 'text', value: 'Linux Ubuntu 22.04' }, // OS 종류
                28: { type: 'radio_text', radio: 'Y', text: 'CyberArk' }, // OS 접근제어
                29: { type: 'radio', value: 'Y' }, // OS 이력 기록
                30: { type: 'radio_textarea', radio: 'Y', textarea: '서버 관리자 승인 후 접속 가능' }, // OS 권한 절차
                31: { type: 'textarea', value: '인프라팀 정과장' }, // OS 관리자
                32: { type: 'textarea', value: '60일마다 강제 변경' }, // OS 패스워드
                33: { type: 'radio_text', radio: 'Y', text: 'Cisco AnyConnect' }, // VPN 사용 여부
                34: { type: 'radio', value: 'Y' }, // 로직 수정 가능 여부
                35: { type: 'radio', value: 'Y' }, // 변경 이력 기록
                36: { type: 'radio_textarea', radio: 'Y', textarea: '개발팀 부서장 승인 절차' }, // 변경 승인
                37: { type: 'radio_textarea', radio: 'Y', textarea: '현업 담당자 테스트 완료 후 이관' }, // 사용자 테스트
                38: { type: 'radio_textarea', radio: 'Y', textarea: '이관 승인 요청서 작성' }, // 이관 승인
                39: { type: 'textarea', value: '배포 담당자 최책임' }, // 이관 권한자
                40: { type: 'radio', value: 'Y' }, // 개발/운영 분리
                41: { type: 'radio', value: 'Y' }, // 배치 스케줄 존재
                42: { type: 'radio_text', radio: 'Y', text: 'Control-M' }, // 배치 툴
                43: { type: 'radio', value: 'Y' }, // 배치 이력 기록
                44: { type: 'radio_textarea', radio: 'Y', textarea: '스케줄 등록 전 승인 필수' }, // 배치 승인
                45: { type: 'textarea', value: '운영팀 전체' }, // 배치 권한자
                46: { type: 'textarea', value: '24시간 관제 센터 모니터링' }, // 배치 모니터링
                47: { type: 'textarea', value: '장애 발생 시 유선 및 메일 전파' }, // 장애 대응
                48: { type: 'textarea', value: '매일 02시 전체 백업 수행' }, // 백업
                49: { type: 'textarea', value: '지문 인식 및 CCTV 상시 가동' }, // 서버실 출입
                50: { type: 'radio_textarea', radio: 'Y', textarea: '월 1회 보안 패치 현황 점검 및 적용' }, // 보안 패치
                51: { type: 'radio', value: 'Y' } // SOC1 Report 검토/승인
            };

            // 인덱스와 질문 번호 매핑 확인을 위한 디버깅
            console.log(`[SAMPLE DEBUG] 현재 questionNumber: ${questionNumber}`);
            const sample = samples[questionNumber];
            console.log(`[SAMPLE] questionNumber: ${questionNumber}, sample:`, sample);
            if (!sample) {
                console.log(`[SAMPLE] 샘플 데이터가 없습니다: ${questionNumber} - 자동으로 다음 질문으로 넘어갑니다`);
                // 샘플 데이터가 없으면 자동으로 다음 질문으로 넘어가기
                setTimeout(function () {
                    const submitBtn = document.querySelector('button[type="submit"]');
                    if (submitBtn) {
                        console.log(`[SAMPLE] 샘플 데이터 없음 - 자동 다음 질문 이동`);
                        submitBtn.click();
                    }
                }, 100);
                return;
            }
            // 텍스트 입력
            if (sample.type === 'text') {
                if (sample.value === '') {
                    console.log(`[SAMPLE] 텍스트 값이 비어있음 - 자동으로 다음 질문으로 넘어갑니다`);
                    setTimeout(function () {
                        const submitBtn = document.querySelector('button[type="submit"]');
                        if (submitBtn) submitBtn.click();
                    }, 100);
                    return;
                }
                const input = document.querySelector(`input[name='a${currentIndex}']`);
                if (input) input.value = sample.value;
            }
            // 라디오만
            if (sample.type === 'radio') {
                if (sample.value === '') {
                    console.log(`[SAMPLE] 라디오 값이 비어있음 - 자동으로 다음 질문으로 넘어갑니다`);
                    setTimeout(function () {
                        const submitBtn = document.querySelector('button[type="submit"]');
                        if (submitBtn) submitBtn.click();
                    }, 100);
                    return;
                }
                const radio = document.querySelector(`input[name='a${currentIndex}'][value='${sample.value}']`);
                if (radio) radio.checked = true;
            }
            // 라디오+텍스트
            if (sample.type === 'radio_text') {
                const radio = document.querySelector(`input[name='a${currentIndex}'][value='${sample.radio}']`);
                if (radio) radio.checked = true;
                const input = document.querySelector(`input[name='a${currentIndex}_1']`);
                if (input) input.value = sample.text;
            }
            // 라디오+textarea
            if (sample.type === 'radio_textarea') {
                const radio = document.querySelector(`input[name='a${currentIndex}'][value='${sample.radio}']`);
                if (radio) radio.checked = true;
                const textarea = document.getElementById(`textarea_${currentIndex}`);
                if (textarea) {
                    if (sample.radio === 'Y') {
                        // "예" 선택시: textarea 활성화하고 값 입력
                        textarea.removeAttribute('readonly');
                        textarea.value = sample.textarea;
                        textarea.required = true;
                        textarea.style.cursor = 'text';
                    } else {
                        // "아니요" 선택시: textarea 비활성화
                        textarea.setAttribute('readonly', true);
                        textarea.value = '';
                        textarea.required = false;
                        textarea.style.cursor = 'not-allowed';
                    }
                }
            }
            // textarea만
            if (sample.type === 'textarea') {
                const textarea = document.querySelector(`textarea[name='a${currentIndex}']`);
                if (textarea) {
                    textarea.value = sample.value;
                    textarea.dispatchEvent(new Event('input', { bubbles: true }));
                }
            }
            // 자동으로 다음(제출) 버튼 클릭
            setTimeout(function () {
                const submitBtn = document.querySelector('button[type="submit"]');
                console.log(`[SAMPLE] 제출 버튼 찾음:`, submitBtn);
                if (submitBtn) {
                    console.log(`[SAMPLE] 제출 버튼 클릭 실행`);
                    submitBtn.click();
                } else {
                    console.log(`[SAMPLE] 제출 버튼을 찾을 수 없습니다`);
                }
            }, 100); // 입력 후 약간의 딜레이
        }

        function fillSkipSample(questionNumber, currentIndex) {
            console.log(`[SKIP SAMPLE] fillSkipSample 호출됨 - questionNumber: ${questionNumber}, currentIndex: ${currentIndex}`);

            // 스킵 조건을 만족하는 샘플값 정의 (모든 가능한 질문 스킵)
            const skipSamples = {
                0: { type: 'text', value: 'snowball1566@gmail.com' }, // 이메일
                1: { type: 'text', value: 'SAP ERP' }, // 시스템 이름
                2: { type: 'radio_text', radio: 'Y', text: 'SAP S/4HANA' }, // 상용소프트웨어
                3: { type: 'radio', value: 'N' }, // Cloud 서비스 사용 안함 → 4~5번 스킵
                4: { type: 'radio', value: 'IaaS' }, // 어떤 종류의 Cloud입니까? (스킵되지만 기본값 제공)
                5: { type: 'radio', value: 'Y' }, // Cloud 서비스 업체에서는 SOC1 Report를 발행하고 있습니까? (스킵되지만 기본값 제공)
                6: { type: 'radio', value: 'N' }, // 권한부여 이력 미기록
                7: { type: 'radio', value: 'N' }, // 권한회수 이력 미기록
                8: { type: 'radio', value: 'Y' },                                               // 개인별 발급(Y) → Q9 스킵, APD01~APD03 절차 표시
                // 9: apd15_shared_mgmt - APD15=Y 시 자동 스킵
                10: { type: 'radio_textarea', radio: 'N', textarea: '' },                      // 권한 승인 절차 없음
                11: { type: 'radio_textarea', radio: 'N', textarea: '' },                      // 권한 회수 절차 없음
                12: { type: 'radio_textarea', radio: 'N', textarea: '' },                      // 퇴사자 권한 차단 절차 없음
                13: { type: 'textarea', value: '' },                                            // Application 관리자
                14: { type: 'radio_textarea', radio: 'N', textarea: '' },                      // 권한 모니터링 절차 없음
                15: { type: 'textarea', value: '' },                                            // 패스워드 정책
                16: { type: 'radio', value: 'N' },                                              // DB 접속 불가 → 17~25번 스킵
                17: { type: 'radio', value: 'N' }, // 데이터 변경 이력 미기록 (스킵되지만 기본값 제공)
                18: { type: 'radio_textarea', radio: 'N', textarea: '' }, // 데이터 변경 승인 절차 없음 (스킵되지만 기본값 제공)
                19: { type: 'textarea', value: '' }, // 데이터 변경 권한자 (스킵되지만 기본값 제공)
                20: { type: 'text', value: 'MySQL 8.0' }, // DB 종류와 버전 (스킵되지만 기본값 제공)
                21: { type: 'radio_text', radio: 'N', text: '' }, // DB 접근제어 Tool 미사용 (스킵되지만 기본값 제공)
                22: { type: 'radio', value: 'N' }, // DB 접근권한 부여 이력 미기록 (스킵되지만 기본값 제공)
                23: { type: 'radio_textarea', radio: 'N', textarea: '' }, // DB 접근권한 승인 절차 없음 (스킵되지만 기본값 제공)
                24: { type: 'textarea', value: '' }, // DB 관리자 권한자 (스킵되지만 기본값 제공)
                25: { type: 'textarea', value: '' }, // DB 패스워드 정책 (스킵되지만 기본값 제공)
                26: { type: 'radio', value: 'N' }, // OS 접속 불가 → 27~32번 스킵
                27: { type: 'text', value: 'Linux Ubuntu 20.04' }, // OS 종류와 버전 (스킵되지만 기본값 제공)
                28: { type: 'radio_text', radio: 'N', text: '' }, // OS 접근제어 Tool 미사용 (스킵되지만 기본값 제공)
                29: { type: 'radio', value: 'N' }, // OS 접근권한 부여 이력 미기록 (스킵되지만 기본값 제공)
                30: { type: 'radio_textarea', radio: 'N', textarea: '' }, // OS 접근권한 승인 절차 없음 (스킵되지만 기본값 제공)
                31: { type: 'textarea', value: '' }, // OS 관리자 권한자 (스킵되지만 기본값 제공)
                32: { type: 'textarea', value: '' }, // OS 패스워드 정책 (스킵되지만 기본값 제공)
                33: { type: 'radio_text', radio: 'N', text: '' }, // VPN 미사용
                34: { type: 'radio', value: 'N' }, // 프로그램 변경 불가 → 35~40번 스킵
                35: { type: 'radio', value: 'N' }, // 프로그램 변경 이력 미기록 (스킵되지만 기본값 제공)
                36: { type: 'radio_textarea', radio: 'N', textarea: '' }, // 프로그램 변경 승인 절차 없음 (스킵되지만 기본값 제공)
                37: { type: 'radio_textarea', radio: 'N', textarea: '' }, // 사용자 테스트 절차 없음 (스킵되지만 기본값 제공)
                38: { type: 'radio_textarea', radio: 'N', textarea: '' }, // 이관 승인 절차 없음 (스킵되지만 기본값 제공)
                39: { type: 'textarea', value: '' }, // 이관 권한자 (스킵되지만 기본값 제공)
                40: { type: 'radio', value: 'N' }, // 개발/테스트 서버 미운용 (스킵되지만 기본값 제공)
                41: { type: 'radio', value: 'N' }, // 배치 스케줄 없음 → 42~46번 스킵
                42: { type: 'radio_text', radio: 'N', text: '' }, // Batch Schedule Tool 미사용 (스킵되지만 기본값 제공)
                43: { type: 'radio', value: 'N' }, // 배치 스케줄 등록/변경 이력 미기록 (스킵되지만 기본값 제공)
                44: { type: 'radio_textarea', radio: 'N', textarea: '' }, // 배치 스케줄 승인 절차 없음 (스킵되지만 기본값 제공)
                45: { type: 'textarea', value: '' }, // 배치 스케줄 권한자 (스킵되지만 기본값 제공)
                46: { type: 'textarea', value: '' }, // 배치 모니터링 (스킵되지만 기본값 제공)
                47: { type: 'textarea', value: '장애 대응 무시' }, // 장애 대응
                48: { type: 'textarea', value: '백업 안함' }, // 백업 절차
                49: { type: 'textarea', value: '서버실 없음' } // 서버실 출입 절차
            };

            const sample = skipSamples[questionNumber];
            console.log(`[SKIP SAMPLE] questionNumber: ${questionNumber}, sample:`, sample);
            if (!sample) {
                console.log(`[SKIP SAMPLE] 스킵 샘플 데이터가 없습니다: ${questionNumber} - 자동으로 다음 질문으로 넘어갑니다`);
                // 샘플 데이터가 없으면 자동으로 다음 질문으로 넘어가기
                setTimeout(function () {
                    const submitBtn = document.querySelector('button[type="submit"]');
                    if (submitBtn) {
                        console.log(`[SKIP SAMPLE] 샘플 데이터 없음 - 자동 다음 질문 이동`);
                        submitBtn.click();
                    }
                }, 100);
                return;
            }

            // fillSample과 동일한 입력 로직 사용 (빈 값 처리 포함)
            if (sample.type === 'text') {
                if (sample.value === '') {
                    console.log(`[SKIP SAMPLE] 텍스트 값이 비어있음 - 자동으로 다음 질문으로 넘어갑니다`);
                    setTimeout(function () {
                        const submitBtn = document.querySelector('button[type="submit"]');
                        if (submitBtn) submitBtn.click();
                    }, 100);
                    return;
                }
                const input = document.querySelector(`input[name='a${currentIndex}']`);
                if (input) input.value = sample.value;
            }
            if (sample.type === 'radio') {
                if (sample.value === '') {
                    console.log(`[SKIP SAMPLE] 라디오 값이 비어있음 - 자동으로 다음 질문으로 넘어갑니다`);
                    setTimeout(function () {
                        const submitBtn = document.querySelector('button[type="submit"]');
                        if (submitBtn) submitBtn.click();
                    }, 100);
                    return;
                }
                const radio = document.querySelector(`input[name='a${currentIndex}'][value='${sample.value}']`);
                if (radio) radio.checked = true;
            }
            if (sample.type === 'radio_text') {
                const radio = document.querySelector(`input[name='a${currentIndex}'][value='${sample.radio}']`);
                if (radio) radio.checked = true;
                const input = document.querySelector(`input[name='a${currentIndex}_1']`);
                if (input) input.value = sample.text;
            }
            if (sample.type === 'radio_textarea') {
                const radio = document.querySelector(`input[name='a${currentIndex}'][value='${sample.radio}']`);
                if (radio) radio.checked = true;
                const textarea = document.getElementById(`textarea_${currentIndex}`);
                if (textarea) {
                    if (sample.radio === 'Y') {
                        textarea.removeAttribute('readonly');
                        textarea.value = sample.textarea;
                        textarea.required = true;
                        textarea.style.cursor = 'text';
                    } else {
                        textarea.setAttribute('readonly', true);
                        textarea.value = '';
                        textarea.required = false;
                        textarea.style.cursor = 'not-allowed';
                    }
                }
            }
            if (sample.type === 'textarea') {
                const textarea = document.querySelector(`textarea[name='a${currentIndex}']`);
                if (textarea) {
                    textarea.value = sample.value;
                    if (sample.value === '') {
                        textarea.removeAttribute('required');
                    } else {
                        textarea.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                }
            }
            if (sample.type === 'skip') {
                console.log(`[SKIP SAMPLE] 질문 ${questionNumber}번은 자동입력하지 않음`);
                return; // 자동입력하지 않고 종료
            }

            // 자동으로 다음(제출) 버튼 클릭
            setTimeout(function () {
                const submitBtn = document.querySelector('button[type="submit"]');
                console.log(`[SKIP SAMPLE] 제출 버튼 찾음:`, submitBtn);
                if (submitBtn) {
                    console.log(`[SKIP SAMPLE] 제출 버튼 클릭 실행`);
                    submitBtn.click();
                } else {
                    console.log(`[SKIP SAMPLE] 제출 버튼을 찾을 수 없습니다`);
                }
            }, 100);
        }

        // 단축키: Ctrl+Shift+S로 샘플입력, Ctrl+Shift+D로 스킵샘플 실행
        document.addEventListener('keydown', function (e) {
            if (e.ctrlKey && e.shiftKey && (e.key === 's' || e.key === 'S')) {
                e.preventDefault();
                const questionNumber = {{ actual_question_number - 1 if actual_question_number else current_index }};
                const currentIndex = {{ current_index }};
                fillSample(questionNumber, currentIndex);
            }
            if (e.ctrlKey && e.shiftKey && (e.key === 'd' || e.key === 'D')) {
                e.preventDefault();
                const questionNumber = {{ actual_question_number - 1 if actual_question_number else current_index }};
                const currentIndex = {{ current_index }};
                fillSkipSample(questionNumber, currentIndex);
            }
        });
        // 마지막 질문 제출 시 서버에서 AI 검토 선택 페이지로 리디렉션됨
        // JavaScript 인터셉트 제거하여 정상적인 서버 처리 허용
    </script>
</body>

</html>