package specifications

const (
	defaultLimit  = int64(50)
	defaultOffset = int64(0)
	defaultPage   = int64(1)
)

type Paging struct {
	limit  int64
	offset int64
	page   int64
}

func NewPaging(page *int64, size *int64) Paging {
	result := Paging{
		limit:  defaultLimit,
		offset: defaultOffset,
		page:   defaultPage,
	}

	if size != nil {
		if *size <= 0 {
			result.limit = defaultLimit
		} else if *size > defaultLimit {
			result.limit = defaultLimit
		} else {
			result.limit = *size
		}
	}

	if page != nil {
		if *page <= 0 {
			result.page = defaultPage
			result.offset = defaultOffset
		} else {
			result.page = *page
			result.offset = (*page - 1) * result.limit
		}
	}

	return result
}

func (p Paging) GetLimit() int64 {
	return p.limit
}

func (p Paging) GetOffset() int64 {
	return p.offset
}

func (p Paging) GetPage() int64 {
	return p.page
}
