<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snowball - ITGC 인터뷰 ({{ section_info.name }})</title>
    <link rel="icon" type="image/x-icon" href="{{ url_for('static', filename='img/favicon.ico') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/common.css') }}" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css') }}" rel="stylesheet">
    <style>
        /* 섹션 스텝 인디케이터 */
        .section-steps {
            display: flex;
            justify-content: center;
            gap: 0.5rem;
            margin: 1.5rem 0 2rem;
            flex-wrap: wrap;
        }
        .step {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 0.6rem 1.2rem;
            border-radius: 0.5rem;
            border: 2px solid #dee2e6;
            color: #adb5bd;
            min-width: 120px;
            font-size: 0.85rem;
            transition: all 0.2s;
        }
        .step i { font-size: 1.3rem; margin-bottom: 0.2rem; }
        .step.completed { border-color: #198754; color: #198754; background: #d1e7dd; cursor: pointer; }
        .step.completed:hover { border-color: #146c43; background: #a3cfbb; text-decoration: none; }
        .step.active    { border-color: #0d6efd; color: #0d6efd; background: #e7f1ff; font-weight: 600; }
        a.step { text-decoration: none; }

        /* 질문 블록 */
        .question-block { margin-bottom: 1.2rem; }
        .question-block.hidden { display: none !important; }
        .q-num { color: #6c757d; font-size: 0.8rem; font-weight: 500; margin-bottom: 0.25rem; }
        .q-text { font-weight: 600; font-size: 0.98rem; margin-bottom: 0.5rem; }
        .q-help { font-size: 0.83rem; color: #6c757d; border-left: 3px solid #dee2e6; padding-left: 0.6rem; margin-top: 0.4rem; }

        /* Y/N 버튼 */
        .yn-wrap { display: flex; gap: 0.5rem; flex-wrap: wrap; margin-top: 0.5rem; }
        .yn-wrap .btn { flex: none; width: 80px !important; max-width: 80px !important; min-width: 0 !important; font-size: 0.875rem; padding: 0.25rem 0.75rem; }

        /* 다크모드 텍스트 */
        html[data-bs-theme="dark"] h2,
        html[data-bs-theme="dark"] h3,
        html[data-bs-theme="dark"] .q-text { color: #e9ecef; }
        html[data-bs-theme="dark"] .q-num,
        html[data-bs-theme="dark"] p.text-muted { color: #adb5bd !important; }

        /* 구분선 */
        .section-divider { border-top: 2px solid #e9ecef; margin: 2rem 0 1.5rem; padding-top: 1rem; }
        .sub-section-title { font-size: 0.9rem; font-weight: 600; color: #495057;
                             background: #f8f9fa; padding: 0.4rem 0.8rem; border-radius: 0.3rem;
                             margin-bottom: 0.8rem; display: inline-block; }
    </style>
</head>
<body>
    {% include 'navi.jsp' %}

    <div class="container mt-4">

        <!-- 섹션 스텝 인디케이터 -->
        <div class="section-steps">
            {% for s_key in section_order %}
            {% set s = sections[s_key] %}
            {% set s_idx = loop.index0 %}
            {% if s_idx < cur_section_idx %}
            <a href="{{ url_for('link2_1p.section_view', section_name=s_key) }}"
               class="step completed">
                <i class="fas {{ s.icon }}"></i>
                <span>{{ s.name.split('(')[0].strip() }}</span>
            </a>
            {% else %}
            <div class="step {% if s_idx == cur_section_idx %}active{% endif %}">
                <i class="fas {{ s.icon }}"></i>
                <span>{{ s.name.split('(')[0].strip() }}</span>
            </div>
            {% endif %}
            {% endfor %}
        </div>

        <!-- 섹션 제목 -->
        <h2 class="mb-1">
            <i class="fas {{ section_info.icon }} me-2"></i>{{ section_info.name }}
        </h2>
        <p class="text-muted mb-3" style="font-size:0.9rem;">
            아래 질문에 답변 후 하단 버튼으로 이동하세요.
            조건에 따라 일부 질문은 자동으로 숨겨집니다.
        </p>

        <!-- 관리자용 샘플 입력 -->
        {% if remote_addr == '127.0.0.1' or (user_info and user_info.get('admin_flag') == 'Y') %}
        <div class="mb-3">
            <button type="button" class="btn btn-outline-secondary btn-sm me-2" onclick="fillAllSamples()">
                <i class="fas fa-magic"></i> 샘플입력
            </button>
        </div>
        {% endif %}

        <!-- 폼 -->
        <form id="sectionForm"
              action="{{ url_for('link2_1p.section_view', section_name=section_name) }}"
              method="post">
            <input type="hidden" name="csrf_token" value="{{ csrf_token() }}" />

            {% block section_content %}{% endblock %}

            <!-- 이전/다음 버튼 -->
            <div class="d-flex justify-content-between align-items-center mt-4 mb-5 pt-3"
                 style="border-top: 1px solid #dee2e6;">
                {% if prev_section %}
                <a href="{{ url_for('link2_1p.section_view', section_name=prev_section) }}"
                   class="btn btn-outline-secondary px-4">
                    <i class="fas fa-arrow-left me-1"></i> 이전
                </a>
                {% else %}
                <div></div>
                {% endif %}

                <button type="submit" class="btn btn-primary px-4">
                    {% if is_last %}
                    <i class="fas fa-check me-1"></i> 완료 및 제출
                    {% else %}
                    다음 <i class="fas fa-arrow-right ms-1"></i>
                    {% endif %}
                </button>
            </div>
        </form>

    </div>{# /container #}

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
    // ================================================================
    // 공통 유틸리티 함수
    // ================================================================

    /** 질문 idx의 현재 값을 반환 (hidden_input / radio / text / textarea) */
    function getVal(idx) {
        const hidden = document.getElementById(`q${idx}_hidden`);
        if (hidden) return hidden.value;
        const checked = document.querySelector(`input[name="q${idx}"]:checked`);
        if (checked) return checked.value;
        const el = document.querySelector(`input[name="q${idx}"], textarea[name="q${idx}"]`);
        return el ? el.value : '';
    }

    /** Y/N 버튼 토글 (hidden input + 버튼 스타일 갱신) */
    function setYN(idx, value) {
        const hidden = document.getElementById(`q${idx}_hidden`);
        if (hidden) hidden.value = value;
        const yes = document.getElementById(`q${idx}_yes`);
        const no  = document.getElementById(`q${idx}_no`);
        if (yes) {
            yes.classList.toggle('btn-primary',       value === 'Y');
            yes.classList.toggle('btn-outline-secondary', value !== 'Y');
            yes.style.setProperty('width', '80px', 'important');
        }
        if (no) {
            no.classList.toggle('btn-primary',          value === 'N');
            no.classList.toggle('btn-outline-secondary', value !== 'N');
            no.style.setProperty('width', '80px', 'important');
        }
        applyConditions();
    }

    /** 질문 블록 표시/숨김 */
    function toggleQ(idx, show) {
        const el = document.getElementById(`qblock_${idx}`);
        if (!el) return;
        el.classList.toggle('hidden', !show);
        // 숨긴 필드의 required 제거, 다시 표시 시 복원
        el.querySelectorAll('input, textarea, select').forEach(f => {
            if (!show) {
                if (f.required) { f.dataset.wasRequired = '1'; f.removeAttribute('required'); }
            } else {
                if (f.dataset.wasRequired) { f.setAttribute('required', ''); delete f.dataset.wasRequired; }
            }
        });
        renumberQuestions();
    }

    /** 연속 범위 표시/숨김 */
    function toggleRange(start, end, show) {
        for (let i = start; i <= end; i++) toggleQ(i, show);
    }

    /** 표시 중인 질문 번호 순차 재계산 */
    function renumberQuestions() {
        let num = 1;
        document.querySelectorAll('.question-block').forEach(function(block) {
            if (block.classList.contains('hidden')) return;
            const numEl = block.querySelector('.q-num');
            if (!numEl) return;
            const badge = numEl.querySelector('.badge');
            numEl.textContent = 'Q' + num++;
            if (badge) numEl.appendChild(badge);
        });
    }

    // ── answer_type 3 (Y/N + text input) ──────────────────────────
    function toggleTextInput3(idx) {
        const textEl = document.getElementById(`q${idx}_text_input`);
        const yesR   = document.querySelector(`input[name="q${idx}"][value="Y"]`);
        const noR    = document.querySelector(`input[name="q${idx}"][value="N"]`);
        if (!textEl || !yesR || !noR) return;
        if (yesR.checked) {
            textEl.removeAttribute('disabled');
            textEl.required = true;
            textEl.style.cursor = '';
            textEl.style.backgroundColor = '';
            textEl.placeholder = textEl.dataset.origPlaceholder || '';
        } else {
            if (!textEl.dataset.origPlaceholder) textEl.dataset.origPlaceholder = textEl.placeholder;
            textEl.setAttribute('disabled', true);
            textEl.value = '';
            textEl.required = false;
            textEl.style.cursor = 'not-allowed';
            textEl.style.backgroundColor = '#e9ecef';
            textEl.placeholder = '';
        }
    }

    // ── answer_type 4 (Y/N + textarea) ────────────────────────────
    function toggleTextarea4(idx) {
        const wrap = document.getElementById(`q${idx}_ta_wrap`);
        const ta   = document.getElementById(`q${idx}_ta`);
        const yesR = document.querySelector(`input[name="q${idx}"][value="Y"]`);
        if (!wrap || !ta || !yesR) return;
        if (yesR.checked) {
            wrap.classList.remove('d-none');
            ta.required = true;
        } else {
            wrap.classList.add('d-none');
            ta.value = '';
            ta.required = false;
        }
    }

    /** 기본 applyConditions (각 섹션에서 override) */
    function applyConditions() {}

    /** fillAllSamples (각 섹션에서 override) */
    function fillAllSamples() {}

    document.addEventListener('DOMContentLoaded', function() {
        document.querySelectorAll('.yn-wrap .btn').forEach(function(btn) {
            btn.style.setProperty('width', '80px', 'important');
        });
    });
    </script>
    {% block section_scripts %}{% endblock %}
</body>
</html>
