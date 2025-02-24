/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import {render as rtlRender, fireEvent} from '@testing-library/react'

import ManageOutcomeItem from '../ManageOutcomeItem'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {MockedProvider} from '@apollo/react-testing'

const render = (
  children,
  {canManage = true, isAdmin = true, contextType = 'Account', renderer = rtlRender} = {}
) => {
  return renderer(
    <OutcomesContext.Provider value={{env: {canManage, isAdmin, contextType}}}>
      <MockedProvider mocks={[]}>{children}</MockedProvider>
    </OutcomesContext.Provider>
  )
}

describe('ManageOutcomeItem', () => {
  let onMenuHandlerMock
  let onCheckboxHandlerMock
  const defaultProps = (props = {}) => ({
    linkId: '2',
    title: 'Outcome Title',
    description: 'Outcome Description',
    outcomeContextType: 'Account',
    outcomeContextId: '1',
    isChecked: false,
    canManageOutcome: true,
    canUnlink: true,
    onMenuHandler: onMenuHandlerMock,
    onCheckboxHandler: onCheckboxHandlerMock,
    ...props
  })

  beforeEach(() => {
    onMenuHandlerMock = jest.fn()
    onCheckboxHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders title if title prop passed', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    expect(getByText('Outcome Title')).toBeInTheDocument()
  })

  it('does not render component if title prop not passed', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps({title: ''})} />)
    expect(queryByTestId('outcome-management-item')).not.toBeInTheDocument()
  })

  it('handles click on checkbox', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    const checkbox = getByText('Select outcome')
    fireEvent.click(checkbox)
    expect(onCheckboxHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('passes selected outcome obj to checkbox onClick handler', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    const checkbox = getByText('Select outcome')
    fireEvent.click(checkbox)
    expect(onCheckboxHandlerMock).toHaveBeenCalledWith({linkId: '2'})
  })

  it('displays right pointing caret when description is truncated', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps()} />)
    expect(queryByTestId('icon-arrow-right')).toBeInTheDocument()
  })

  it('displays down pointing caret when description is expanded', () => {
    const {queryByTestId, getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Expand outcome description'))
    expect(queryByTestId('icon-arrow-down')).toBeInTheDocument()
  })

  it('expands description when user clicks on button with right pointing caret', () => {
    const {queryByTestId, getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    const caretBtn = getByText('Expand outcome description')
    fireEvent.click(caretBtn)
    expect(queryByTestId('description-expanded')).toBeInTheDocument()
  })

  it('collapses description when user clicks on button with down pointing caret', () => {
    const {queryByTestId, getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    const caretBtn = getByText('Expand outcome description')
    fireEvent.click(caretBtn)
    const caretDownBtn = getByText('Collapse outcome description')
    fireEvent.click(caretDownBtn)
    expect(queryByTestId('description-truncated')).toBeInTheDocument()
  })

  it('displays disabled caret button with "not-allowed" cursor if no description', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps({description: null})} />)
    expect(queryByTestId('icon-arrow-right').closest('button')).toHaveAttribute('disabled')
    expect(queryByTestId('icon-arrow-right').closest('button').style).toHaveProperty(
      'cursor',
      'not-allowed'
    )
  })

  it('handles click on individual outcome -> kebab menu -> remove option', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Outcome Menu'))
    fireEvent.click(getByText('Remove'))
    expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
    expect(onMenuHandlerMock.mock.calls[0][0]).toBe('2')
    expect(onMenuHandlerMock.mock.calls[0][1]).toBe('remove')
  })

  describe('when canManageOutcome is false', () => {
    it('hides the kebab menu', () => {
      const {queryByText} = render(
        <ManageOutcomeItem {...defaultProps({canManageOutcome: false})} />
      )
      expect(queryByText('Outcome Menu')).not.toBeInTheDocument()
    })

    it('hides checkboxes', () => {
      const {queryByText} = render(
        <ManageOutcomeItem {...defaultProps({canManageOutcome: false})} />
      )
      expect(queryByText('Select outcome')).not.toBeInTheDocument()
    })

    describe('with manage_outcomes permission', () => {
      it('renders the kebab menu if the user is an admin within the course context', () => {
        const {getByText} = render(
          <ManageOutcomeItem {...defaultProps({canManageOutcome: false})} />,
          {
            isAdmin: true,
            canManage: true,
            contextType: 'Course'
          }
        )
        expect(getByText('Outcome Menu')).toBeInTheDocument()
      })

      it('does not render the kebab menu if the user is not an admin', () => {
        const {queryByText} = render(
          <ManageOutcomeItem {...defaultProps({canManageOutcome: false})} />,
          {
            isAdmin: false,
            canManage: true,
            contextType: 'Course'
          }
        )
        expect(queryByText('Outcome Menu')).not.toBeInTheDocument()
      })
    })
  })
})
