<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowball - RCM 사용자 관리</title>
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
                    <h1><i class="fas fa-users me-2"></i>RCM 사용자 관리</h1>
                    <div>
                        <a href="/rcm/{{ rcm_info.rcm_id }}/select" class="btn btn-info me-2">
                            <i class="fas fa-eye me-1"></i>RCM 보기
                        </a>
                        <a href="/rcm" class="btn btn-secondary">
                            <i class="fas fa-arrow-left me-1"></i>목록으로
                        </a>
                    </div>
                </div>
                <hr>
            </div>
        </div>

        <!-- RCM 기본 정보 -->
        <div class="row mb-4">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-info-circle me-2"></i>RCM 정보</h5>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-4">
                                <strong>RCM명:</strong> {{ rcm_info.rcm_name }}
                            </div>
                            <div class="col-md-4">
                                <strong>회사명:</strong> {{ rcm_info.company_name }}
                            </div>
                            <div class="col-md-4">
                                <strong>접근 권한 사용자:</strong> <span class="badge bg-primary">{{ rcm_users|length }}명</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <!-- 현재 접근 권한 사용자 목록 -->
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-list me-2"></i>접근 권한이 있는 사용자</h5>
                    </div>
                    <div class="card-body">
                        {% if rcm_users %}
                        <div class="table-responsive">
                            <table class="table table-striped">
                                <thead>
                                    <tr>
                                        <th>사용자</th>
                                        <th>회사명</th>
                                        <th>권한</th>
                                        <th>부여일</th>
                                        <th>부여자</th>
                                        <th>관리</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {% for user in rcm_users %}
                                    <tr>
                                        <td>
                                            <strong>{{ user.user_name }}</strong><br>
                                            <small class="text-muted">{{ user.user_email }}</small>
                                        </td>
                                        <td>{{ user.company_name }}</td>
                                        <td>
                                            <span class="badge bg-{{ 'danger' if user.permission_type == 'admin' else 'success' }}">
                                                {{ '관리자' if user.permission_type == 'admin' else '읽기' }}
                                            </span>
                                        </td>
                                        <td>{{ user.granted_date.split(' ')[0] if user.granted_date else '-' }}</td>
                                        <td>{{ user.granted_by_name or '시스템' }}</td>
                                        <td>
                                            <button class="btn btn-sm btn-warning" onclick="changePermission({{ user.user_id }}, '{{ user.user_name }}', '{{ user.permission_type }}')">
                                                <i class="fas fa-edit"></i>
                                            </button>
                                            <button class="btn btn-sm btn-danger" onclick="revokeAccess({{ user.user_id }}, '{{ user.user_name }}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                        </td>
                                    </tr>
                                    {% endfor %}
                                </tbody>
                            </table>
                        </div>
                        {% else %}
                        <div class="text-center py-4">
                            <i class="fas fa-users-slash fa-2x text-muted mb-2"></i>
                            <p class="text-muted">접근 권한이 부여된 사용자가 없습니다.</p>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>

            <!-- 사용자 권한 부여 -->
            <div class="col-md-4">
                <div class="card">
                    <div class="card-header">
                        <h5><i class="fas fa-user-plus me-2"></i>사용자 권한 부여</h5>
                    </div>
                    <div class="card-body">
                        <form id="grantAccessForm">
                            <input type="hidden" name="rcm_id" value="{{ rcm_info.rcm_id }}">
                            
                            <div class="mb-3">
                                <label for="userId" class="form-label">사용자 선택</label>
                                <select class="form-select" name="user_id" id="userId" required>
                                    <option value="">사용자를 선택하세요</option>
                                    {% for user in all_users %}
                                    <option value="{{ user.user_id }}">{{ user.company_name }} - {{ user.user_name }} ({{ user.user_email }})</option>
                                    {% endfor %}
                                </select>
                            </div>
                            
                            <div class="mb-3">
                                <label for="permissionType" class="form-label">권한 유형</label>
                                <select class="form-select" name="permission_type" id="permissionType" required>
                                    <option value="">권한을 선택하세요</option>
                                    <option value="read">읽기 권한</option>
                                    <option value="admin">관리자 권한</option>
                                </select>
                                <div class="form-text">
                                    <small>
                                        <strong>읽기:</strong> RCM 조회만 가능<br>
                                        <strong>관리자:</strong> RCM 수정 및 관리 가능
                                    </small>
                                </div>
                            </div>
                            
                            <button type="submit" class="btn btn-primary w-100">
                                <i class="fas fa-plus me-1"></i>권한 부여
                            </button>
                        </form>
                    </div>
                </div>

                <div class="card mt-4">
                    <div class="card-header">
                        <h6><i class="fas fa-info-circle me-2"></i>권한 안내</h6>
                    </div>
                    <div class="card-body">
                        <ul class="list-unstyled small">
                            <li><i class="fas fa-eye text-success me-2"></i><strong>읽기 권한:</strong> RCM 데이터 조회</li>
                            <li><i class="fas fa-user-shield text-danger me-2"></i><strong>관리자 권한:</strong> RCM 수정/삭제</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 권한 변경 모달 -->
    <div class="modal fade" id="permissionModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">권한 변경</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form id="changePermissionForm">
                    <div class="modal-body">
                        <input type="hidden" name="rcm_id" value="{{ rcm_info.rcm_id }}">
                        <input type="hidden" name="user_id" id="changeUserId">
                        
                        <p>사용자 <strong id="changeUserName"></strong>의 권한을 변경합니다.</p>
                        
                        <div class="mb-3">
                            <label for="newPermissionType" class="form-label">새로운 권한</label>
                            <select class="form-select" name="permission_type" id="newPermissionType" required>
                                <option value="read">읽기 권한</option>
                                <option value="admin">관리자 권한</option>
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">취소</button>
                        <button type="submit" class="btn btn-sm btn-warning">권한 변경</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            console.log('DOMContentLoaded - 스크립트 로드됨');

            const grantForm = document.getElementById('grantAccessForm');
            if (!grantForm) {
                console.error('grantAccessForm을 찾을 수 없습니다!');
                return;
            }
            console.log('grantAccessForm 찾음:', grantForm);

            // 권한 부여
            grantForm.addEventListener('submit', function(e) {
            e.preventDefault();

            const formData = new FormData(this);
            const submitBtn = this.querySelector('button[type="submit"]');

            // 디버깅: FormData 내용 출력
            console.log('FormData contents:');
            for (let [key, value] of formData.entries()) {
                console.log(`${key}: ${value}`);
            }

            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>처리 중...';

            fetch('/admin/rcm/grant_access', {
                method: 'POST',
                body: formData
            })
            .then(response => {
                console.log('Response status:', response.status);
                return response.json();
            })
            .then(data => {
                console.log('Response data:', data);
                if (data.success) {
                    alert(data.message);
                    location.reload();
                } else {
                    alert('오류: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('권한 부여 중 오류가 발생했습니다. 콘솔을 확인하세요.');
            })
            .finally(() => {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fas fa-plus me-1"></i>권한 부여';
            });
            });

            // 권한 변경
            window.changePermission = function(userId, userName, currentPermission) {
                document.getElementById('changeUserId').value = userId;
                document.getElementById('changeUserName').textContent = userName;
                document.getElementById('newPermissionType').value = currentPermission === 'admin' ? 'read' : 'admin';

                new bootstrap.Modal(document.getElementById('permissionModal')).show();
            };

            document.getElementById('changePermissionForm').addEventListener('submit', function(e) {
                e.preventDefault();

                const formData = new FormData(this);

                fetch('/admin/rcm/change_permission', {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert(data.message);
                        location.reload();
                    } else {
                        alert('오류: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('권한 변경 중 오류가 발생했습니다.');
                });
            });

            // 권한 제거
            window.revokeAccess = function(userId, userName) {
                if (!confirm(`${userName} 사용자의 RCM 접근 권한을 제거하시겠습니까?`)) {
                    return;
                }

                const formData = new FormData();
                formData.append('rcm_id', '{{ rcm_info.rcm_id }}');
                formData.append('user_id', userId);

                fetch('/admin/rcm/revoke_access', {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert(data.message);
                        location.reload();
                    } else {
                        alert('오류: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('권한 제거 중 오류가 발생했습니다.');
                });
            };
        });
    </script>
</body>
</html>