<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - RCM 관리</title>
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
        <div class="row">
            <div class="col-12">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h1><i class="fas fa-file-excel me-2"></i>RCM 관리</h1>
                    <a href="/admin/rcm/upload" class="btn btn-primary">
                        <i class="fas fa-plus me-2"></i>새 RCM 업로드
                    </a>
                </div>
                <hr>
            </div>
        </div>

        {% if rcms %}
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-list me-2"></i>등록된 RCM 목록</h5>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-striped table-hover">
                                <thead>
                                    <tr>
                                        <th>RCM명</th>
                                        <th>회사명</th>
                                        <th>설명</th>
                                        <th>소유자</th>
                                        <th>업로드일</th>
                                        <th>관리</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for rcm in rcms %}
                                    <tr>
                                        <td><strong>{{ rcm.rcm_name }}</strong></td>
                                        <td>{{ rcm.company_name or '-' }}</td>
                                        <td>{{ rcm.description or '-' }}</td>
                                        <td>{{ rcm.owner_name or '-' }}</td>
                                        <td>{{ rcm.upload_date.split(' ')[0] if rcm.upload_date else '-' }}</td>
                                        <td>
                                            <a href="/admin/rcm/{{ rcm.rcm_id }}/view" class="btn btn-sm btn-outline-primary">
                                                <i class="fas fa-eye me-1"></i>보기
                                            </a>
                                            <button type="button" class="btn btn-sm btn-outline-warning"
                                                    onclick="editRcm({{ rcm.rcm_id }}, '{{ rcm.rcm_name }}', '{{ rcm.company_name or '' }}', '{{ rcm.description or '' }}')"
                                                    data-bs-toggle="modal" data-bs-target="#editRcmModal">
                                                <i class="fas fa-edit me-1"></i>수정
                                            </button>
                                            <a href="/admin/rcm/{{ rcm.token }}/users" class="btn btn-sm btn-outline-success">
                                                <i class="fas fa-users me-1"></i>사용자
                                            </a>
                                            <button class="btn btn-sm btn-outline-danger" onclick="deleteRcm({{ rcm.rcm_id }}, '{{ rcm.rcm_name }}')">
                                                <i class="fas fa-trash me-1"></i>삭제
                                            </button>
                                        </td>
                                    </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        {% else %}
        <div class="row">
            <div class="col-12">
                <div class="alert alert-info text-center">
                    <i class="fas fa-info-circle fa-2x mb-3"></i>
                    <h5>등록된 RCM이 없습니다</h5>
                    <p>새로운 RCM을 업로드하여 시작하세요.</p>
                    <a href="/admin/rcm/upload" class="btn btn-primary">
                        <i class="fas fa-plus me-2"></i>첫 RCM 업로드
                    </a>
                </div>
            </div>
        </div>
        {% endif %}

        <div class="row mt-4">
            <div class="col-12">
                <a href="/admin" class="btn btn-secondary">
                    <i class="fas fa-arrow-left me-2"></i>관리자 대시보드로 돌아가기
                </a>
            </div>
        </div>
    </div>

    <!-- RCM 수정 모달 -->
    <div class="modal fade" id="editRcmModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">RCM 정보 수정</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form id="editRcmForm" method="post">
                    <input type="hidden" name="csrf_token" value="{{ csrf_token() }}"/>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">RCM명 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="rcm_name" id="edit_rcm_name" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">대상 사용자 (회사명) <span class="text-danger">*</span></label>
                            <select class="form-select" name="target_user_id" id="edit_target_user_id" required>
                                <option value="">사용자를 선택하세요</option>
                                {% for user in users %}
                                <option value="{{ user.user_id }}" data-company="{{ user.company_name or '' }}">
                                    {{ user.company_name or '(회사명 없음)' }} - {{ user.user_name }} ({{ user.user_email }})
                                </option>
                                {% endfor %}
                            </select>
                            <div class="form-text">선택한 사용자의 회사명이 RCM에 자동으로 설정됩니다.</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">설명</label>
                            <textarea class="form-control" name="description" id="edit_description" rows="3"></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" style="width: 100px;">닫기</button>
                        <button type="submit" class="btn btn-primary" style="width: 100px;">수정</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // RCM 수정 함수
        function editRcm(rcmId, rcmName, companyName, description) {
            document.getElementById('editRcmForm').action = '/admin/rcm/edit/' + rcmId;
            document.getElementById('edit_rcm_name').value = rcmName;
            document.getElementById('edit_description').value = description;

            // 회사명과 일치하는 사용자 자동 선택
            const userSelect = document.getElementById('edit_target_user_id');
            userSelect.value = ''; // 초기화

            if (companyName) {
                // 회사명이 일치하는 첫 번째 사용자 선택
                for (let i = 0; i < userSelect.options.length; i++) {
                    const option = userSelect.options[i];
                    const optionCompany = option.getAttribute('data-company');
                    if (optionCompany === companyName) {
                        userSelect.value = option.value;
                        break;
                    }
                }
            }
        }

        // RCM 삭제 함수
        function deleteRcm(rcmId, rcmName) {
            if (!confirm(`'${rcmName}' RCM을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 다음 항목들이 함께 삭제됩니다:\n- RCM 상세 데이터\n- 사용자 접근 권한\n\n정말로 삭제하시겠습니까?`)) {
                return;
            }

            const formData = new FormData();
            formData.append('rcm_id', rcmId);

            // 삭제 버튼 비활성화
            const deleteBtn = event.target.closest('button');
            deleteBtn.disabled = true;
            deleteBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>삭제 중...';

            fetch('/admin/rcm/delete', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    location.reload();
                } else {
                    alert('[ADMIN-005] 삭제 실패: ' + data.message);
                    deleteBtn.disabled = false;
                    deleteBtn.innerHTML = '<i class="fas fa-trash me-1"></i>삭제';
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('[ADMIN-006] RCM 삭제 중 오류가 발생했습니다.');
                deleteBtn.disabled = false;
                deleteBtn.innerHTML = '<i class="fas fa-trash me-1"></i>삭제';
            });
        }
    </script>
</body>
</html>
