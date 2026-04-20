{% include 'navi.jsp' %}
<div style="padding-top: 70px;">
<div class="container-fluid px-4 py-4">

  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h4 class="fw-bold mb-1"><i class="fas fa-tasks text-primary me-2"></i>통제 관리</h4>
      <small class="text-muted">ITGC 기준통제 및 시스템 매핑을 관리합니다.</small>
    </div>
    <button class="btn btn-primary btn-sm" onclick="openAddModal()">
      <i class="fas fa-plus me-1"></i>통제 등록
    </button>
  </div>

  <!-- 카테고리 탭 -->
  <ul class="nav nav-tabs mb-3" id="categoryTabs">
    <li class="nav-item">
      <a class="nav-link active" href="#" onclick="filterCategory('ALL', this)">전체</a>
    </li>
    {% for cat in categories %}
    <li class="nav-item">
      <a class="nav-link" href="#" onclick="filterCategory('{{ cat }}', this)">
        {{ cat }}
        <small class="text-muted ms-1">{{ category_labels.get(cat, '') }}</small>
      </a>
    </li>
    {% endfor %}
  </ul>

  <div class="card shadow-sm border-0">
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-hover mb-0 align-middle" style="font-size:0.9rem;">
          <thead class="table-light">
            <tr>
              <th class="ps-3">카테고리</th>
              <th>통제코드</th>
              <th>통제명</th>
              <th>설명</th>
              <th class="text-center">점검쿼리</th>
              <th class="text-center">상태</th>
              <th class="text-center">시스템 매핑</th>
              <th class="text-center">관리</th>
            </tr>
          </thead>
          <tbody id="controlsTableBody">
            {% for c in controls %}
            <tr class="control-row" data-category="{{ c.category }}">
              <td class="ps-3">
                <span class="badge bg-primary">{{ c.category }}</span>
              </td>
              <td class="fw-semibold">{{ c.control_code }}</td>
              <td>{{ c.control_name }}</td>
              <td class="text-muted small" style="max-width:250px;">{{ c.description or '-' }}</td>
              <td class="text-center">
                {% if c.monitor_query %}
                <i class="fas fa-check-circle text-success" title="{{ c.monitor_query[:100] }}"></i>
                {% else %}
                <i class="fas fa-circle text-muted" title="미설정"></i>
                {% endif %}
              </td>
              <td class="text-center">
                {% if c.is_active == 'Y' %}
                <span class="badge bg-success">활성</span>
                {% else %}
                <span class="badge bg-secondary">비활성</span>
                {% endif %}
              </td>
              <td class="text-center">
                <button class="btn btn-outline-info btn-sm" onclick="openMappingModal({{ c.control_id }}, '{{ c.control_code }}', '{{ c.control_name }}')">
                  <i class="fas fa-link me-1"></i>매핑
                </button>
              </td>
              <td class="text-center">
                <button class="btn btn-outline-secondary btn-sm me-1" onclick="openEditModal({{ c | tojson | safe }})">
                  <i class="fas fa-edit"></i>
                </button>
              </td>
            </tr>
            {% else %}
            <tr><td colspan="8" class="text-center text-muted py-4">등록된 통제가 없습니다.</td></tr>
            {% endfor %}
          </tbody>
        </table>
      </div>
    </div>
  </div>

</div>
</div>

<!-- 통제 등록/수정 모달 -->
<div class="modal fade" id="controlModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="controlModalTitle">통제 등록</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="editControlId">
        <div class="row g-3">
          <div class="col-md-3">
            <label class="form-label fw-semibold">카테고리 <span class="text-danger">*</span></label>
            <select class="form-select" id="controlCategory">
              {% for cat in categories %}
              <option value="{{ cat }}">{{ cat }} - {{ category_labels.get(cat,'') }}</option>
              {% endfor %}
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label fw-semibold">통제코드 <span class="text-danger">*</span></label>
            <input type="text" class="form-control" id="controlCode" placeholder="예: APD-01">
          </div>
          <div class="col-md-6">
            <label class="form-label fw-semibold">통제명 <span class="text-danger">*</span></label>
            <input type="text" class="form-control" id="controlName" placeholder="통제명 입력">
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">설명</label>
            <textarea class="form-control" id="controlDesc" rows="2" placeholder="통제에 대한 설명"></textarea>
          </div>
          <div class="col-12">
            <label class="form-label fw-semibold">기본 점검 쿼리
              <small class="text-muted fw-normal">(시스템별 커스텀 쿼리가 없을 때 사용, 쿼리 결과 = 예외 건수)</small>
            </label>
            <textarea class="form-control font-monospace" id="controlQuery" rows="4"
              placeholder="SELECT * FROM table WHERE condition ..."></textarea>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
        <button class="btn btn-primary" onclick="saveControl()"><i class="fas fa-save me-1"></i>저장</button>
      </div>
    </div>
  </div>
</div>

<!-- 시스템 매핑 모달 -->
<div class="modal fade" id="mappingModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="mappingModalTitle">시스템 매핑</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="mappingControlId">
        <div id="currentMappings" class="mb-3"></div>
        <hr>
        <h6 class="fw-semibold mb-2">새 시스템 연결</h6>
        <div class="row g-2 align-items-end">
          <div class="col-md-4">
            <label class="form-label small fw-semibold">시스템</label>
            <select class="form-select form-select-sm" id="mappingSystemId">
              {% for s in systems %}
              <option value="{{ s.system_id }}">
                {{ s.system_code }} - {{ s.system_name }}
                {% if s.get('has_connector') %}[전용]{% else %}[Generic]{% endif %}
              </option>
              {% endfor %}
            </select>
          </div>
          <div class="col-md-2">
            <label class="form-label small fw-semibold">허용 예외건수</label>
            <input type="number" class="form-control form-control-sm" id="mappingThreshold" value="0" min="0">
          </div>
          <div class="col-md-4">
            <label class="form-label small fw-semibold">커스텀 쿼리 (선택)</label>
            <input type="text" class="form-control form-control-sm" id="mappingQuery" placeholder="기본 쿼리 대신 사용">
          </div>
          <div class="col-md-2">
            <button class="btn btn-primary btn-sm w-100" onclick="addMapping()">
              <i class="fas fa-plus me-1"></i>연결
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
const controlModal  = new bootstrap.Modal(document.getElementById('controlModal'));
const mappingModal  = new bootstrap.Modal(document.getElementById('mappingModal'));

function filterCategory(cat, el) {
    document.querySelectorAll('#categoryTabs .nav-link').forEach(a => a.classList.remove('active'));
    el.classList.add('active');
    document.querySelectorAll('.control-row').forEach(row => {
        row.style.display = (cat === 'ALL' || row.dataset.category === cat) ? '' : 'none';
    });
}

function openAddModal() {
    document.getElementById('controlModalTitle').textContent = '통제 등록';
    document.getElementById('editControlId').value = '';
    ['controlCode','controlName','controlDesc','controlQuery'].forEach(id => document.getElementById(id).value = '');
    document.getElementById('controlCategory').value = 'APD';
    controlModal.show();
}

function openEditModal(c) {
    document.getElementById('controlModalTitle').textContent = '통제 수정';
    document.getElementById('editControlId').value = c.control_id;
    document.getElementById('controlCategory').value = c.category;
    document.getElementById('controlCode').value = c.control_code;
    document.getElementById('controlName').value = c.control_name;
    document.getElementById('controlDesc').value = c.description || '';
    document.getElementById('controlQuery').value = c.monitor_query || '';
    controlModal.show();
}

function saveControl() {
    const controlId = document.getElementById('editControlId').value;
    const payload = {
        category: document.getElementById('controlCategory').value,
        control_code: document.getElementById('controlCode').value.toUpperCase(),
        control_name: document.getElementById('controlName').value,
        description: document.getElementById('controlDesc').value,
        monitor_query: document.getElementById('controlQuery').value,
        is_active: 'Y',
    };
    const url = controlId ? `/api/aegis/controls/${controlId}` : '/api/aegis/controls';
    const method = controlId ? 'PUT' : 'POST';
    fetch(url, { method, headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload) })
    .then(r => r.json())
    .then(data => { alert(data.message); if (data.success) { controlModal.hide(); location.reload(); } });
}

function openMappingModal(controlId, code, name) {
    document.getElementById('mappingControlId').value = controlId;
    document.getElementById('mappingModalTitle').textContent = `시스템 매핑 - ${code} ${name}`;
    document.getElementById('mappingQuery').value = '';
    document.getElementById('mappingThreshold').value = '0';
    loadMappings(controlId);
    mappingModal.show();
}

function loadMappings(controlId) {
    fetch(`/api/aegis/controls/${controlId}/systems`)
    .then(r => r.json())
    .then(data => {
        const rows = (data.mappings || []).map(m => `
            <div class="d-flex justify-content-between align-items-center py-2 border-bottom">
                <div>
                    <span class="badge bg-primary me-2">${m.system_code}</span>${m.system_name}
                    ${m.custom_query ? '<small class="text-muted ms-2"><i class="fas fa-code"></i> 커스텀쿼리</small>' : ''}
                    <small class="text-muted ms-2">허용 예외: ${m.threshold_count}건</small>
                </div>
                <button class="btn btn-outline-danger btn-sm" onclick="removeMapping(${m.mapping_id})">
                    <i class="fas fa-unlink"></i>
                </button>
            </div>`).join('');
        document.getElementById('currentMappings').innerHTML =
            `<h6 class="fw-semibold mb-2">현재 연결된 시스템</h6>${rows || '<p class="text-muted">연결된 시스템 없음</p>'}`;
    });
}

function addMapping() {
    const controlId = document.getElementById('mappingControlId').value;
    const payload = {
        control_id: parseInt(controlId),
        system_id: parseInt(document.getElementById('mappingSystemId').value),
        custom_query: document.getElementById('mappingQuery').value,
        threshold_count: parseInt(document.getElementById('mappingThreshold').value) || 0,
    };
    fetch('/api/aegis/mappings', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload) })
    .then(r => r.json())
    .then(data => { alert(data.message); if (data.success) loadMappings(controlId); });
}

function removeMapping(mappingId) {
    if (!confirm('매핑을 해제하시겠습니까?')) return;
    fetch(`/api/aegis/mappings/${mappingId}`, { method: 'DELETE' })
    .then(r => r.json())
    .then(data => {
        alert(data.message);
        if (data.success) loadMappings(document.getElementById('mappingControlId').value);
    });
}
</script>
