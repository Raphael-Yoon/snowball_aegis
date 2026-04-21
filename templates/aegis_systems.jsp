{% include 'navi.jsp' %}
<div style="padding-top: 70px;">
<div class="container-fluid px-4 py-4">

  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h4 class="fw-bold mb-1"><i class="fas fa-server text-primary me-2"></i>시스템 관리</h4>
      <small class="text-muted">모니터링 대상 시스템을 등록하고 관리합니다.</small>
    </div>
    <button class="btn btn-primary btn-sm" onclick="openAddModal()">
      <i class="fas fa-plus me-1"></i>시스템 등록
    </button>
  </div>

  <div class="card shadow-sm border-0">
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-hover mb-0 align-middle">
          <thead class="table-light">
            <tr>
              <th class="ps-3">코드</th>
              <th>시스템명</th>
              <th>설명</th>
              <th class="text-center">상태</th>
              <th class="text-center">관리</th>
            </tr>
          </thead>
          <tbody id="systemsTableBody">
            {% for s in systems %}
            <tr id="row-{{ s.system_id }}">
              <td class="ps-3 fw-semibold text-primary">{{ s.system_code }}</td>
              <td>{{ s.system_name }}</td>
              <td class="text-muted small">{{ s.description or '-' }}</td>
<td class="text-center">
                {% if s.is_active != 'Y' %}
                  <span class="badge bg-secondary">비활성</span>
                {% elif s.mapped_control_count == 0 %}
                  <span class="badge bg-warning text-dark">통제 미설정</span>
                {% else %}
                  <span class="badge bg-success">준비 완료</span>
                  <div class="text-muted" style="font-size:0.72rem;">통제 {{ s.mapped_control_count }}개</div>
                {% endif %}
              </td>
<td class="text-center">
                <button class="btn btn-outline-secondary btn-sm me-1" onclick='openEditModal({{ s | tojson | safe }})'>
                  <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-outline-danger btn-sm" onclick="deleteSystem({{ s.system_id }}, '{{ s.system_name }}')">
                  <i class="fas fa-trash"></i>
                </button>
              </td>
            </tr>
            {% else %}
            <tr><td colspan="5" class="text-center text-muted py-4">등록된 시스템이 없습니다.</td></tr>
            {% endfor %}
          </tbody>
        </table>
      </div>
    </div>
  </div>

</div>
</div>

<!-- 시스템 등록/수정 모달 -->
<div class="modal fade" id="systemModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="systemModalTitle"><i class="fas fa-server me-2"></i>시스템 등록</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="editSystemId">
        <div class="row g-3">
          <div class="col-md-4">
            <label class="form-label fw-semibold">시스템 코드 <span class="text-danger">*</span></label>
            <input type="text" class="form-control" id="systemCode" placeholder="예: TRADE" style="text-transform:uppercase;">
          </div>
          <div class="col-md-8">
            <label class="form-label fw-semibold">시스템명 <span class="text-danger">*</span></label>
            <input type="text" class="form-control" id="systemName" placeholder="예: 트레이딩 시스템">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">설명</label>
            <input type="text" class="form-control" id="systemDesc" placeholder="시스템에 대한 간략한 설명">
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
        <button class="btn btn-primary" onclick="saveSystem()"><i class="fas fa-save me-1"></i>저장</button>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const systemModal = new bootstrap.Modal(document.getElementById('systemModal'));

function openAddModal() {
    document.getElementById('systemModalTitle').textContent = '시스템 등록';
    document.getElementById('editSystemId').value = '';
    ['systemCode','systemName','systemDesc'].forEach(id =>
        document.getElementById(id).value = '');
    systemModal.show();
}

function openEditModal(s) {
    document.getElementById('systemModalTitle').textContent = '시스템 수정';
    document.getElementById('editSystemId').value = s.system_id;
    document.getElementById('systemCode').value = s.system_code;
    document.getElementById('systemName').value = s.system_name;
    document.getElementById('systemDesc').value = s.description || '';
    systemModal.show();
}

function saveSystem() {
    const systemId = document.getElementById('editSystemId').value;
    const payload = {
        system_code: document.getElementById('systemCode').value.toUpperCase(),
        system_name: document.getElementById('systemName').value,
        description: document.getElementById('systemDesc').value,
        is_active: 'Y',
    };

    const url = systemId ? `/api/aegis/systems/${systemId}` : '/api/aegis/systems';
    const method = systemId ? 'PUT' : 'POST';

    fetch(url, { method, headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload) })
    .then(r => r.json())
    .then(data => {
        alert(data.message);
        if (data.success) { systemModal.hide(); location.reload(); }
    });
}

function deleteSystem(systemId, name) {
    if (!confirm(`'${name}' 시스템을 비활성화하시겠습니까?`)) return;
    fetch(`/api/aegis/systems/${systemId}`, { method: 'DELETE' })
    .then(r => r.json())
    .then(data => { alert(data.message); if (data.success) location.reload(); });
}
</script>
