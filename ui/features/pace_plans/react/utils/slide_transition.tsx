/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Transition} from '@instructure/ui-motion'
import {View} from '@instructure/ui-view'

interface ComponentProps {
  readonly children: any
  readonly direction: 'horizontal' | 'vertical'
  readonly expanded: boolean
  readonly size: string | number
}

const SlideTransition: React.FC<ComponentProps> = ({children, direction, expanded, size}) => {
  const horizontalProps =
    direction === 'horizontal'
      ? {
          as: 'span',
          maxWidth: expanded ? size : '0',
          overflowX: 'hidden'
        }
      : {}
  const verticalProps =
    direction === 'vertical'
      ? {
          as: 'div',
          maxHeight: expanded ? size : '0',
          overflowY: 'hidden'
        }
      : {}
  return (
    <View
      className="pace-plans-collapse"
      data-testid="pace-plans-collapse"
      {...horizontalProps}
      {...verticalProps}
    >
      <Transition in={expanded} type="fade" unmountOnExit theme={{duration: '500ms'}}>
        {children}
      </Transition>
    </View>
  )
}

export default SlideTransition
